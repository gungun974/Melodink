const builtin = @import("builtin");

const std = @import("std");

const fs = std.fs;
const os = std.os;

const c = @import("c.zig");

const Self = @This();

const BLOCK_SIZE = 4096;
const INDEX_FILE = "cache_index.bin";
const DATA_FILE = "cache_data.bin";

const CACHE_MAX_SIZE_DIRECTORY = 1 * 1024 * 1024 * 1024; // 1 GiB max of audio stored

var clean_cache_mutex = std.Thread.Mutex{};

const BUFFER_SIZE = 4096;

protected_opened_cache_paths: *ProtectedOpenedPathsList,
allocator: std.mem.Allocator,
has_been_open: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

source_avio_ctx: [*c]c.AVIOContext = undefined,
avio_ctx: *c.AVIOContext = undefined,

index_map: std.ArrayList(u8),

index_size: usize = 0,
current_offset: u64 = 0,

file_total_size: u64 = 0,

data_file: fs.File = undefined,
index_file: fs.File = undefined,

cache_directory: []const u8 = undefined,

pub const ProtectedOpenedPathsList = struct {
    const Self2 = @This();

    mutex: std.Thread.Mutex = std.Thread.Mutex{},
    data: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
    ) Self2 {
        return .{ .data = std.ArrayList([]const u8).init(allocator), .allocator = allocator };
    }

    pub fn deinit(
        self: *Self2,
    ) void {
        self.data.deinit();
    }

    pub fn protectPath(self: *Self2, path: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        try self.data.append(path);
    }

    pub fn unprotectPath(self: *Self2, path: []const u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (0.., self.data.items) |i, protected| {
            if (std.mem.eql(u8, protected, path)) {
                _ = self.data.swapRemove(i);
                return;
            }
        }
    }

    pub fn isPathProtect(self: *Self2, path: []const u8) bool {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (self.data.items) |protected| {
            if (std.mem.eql(u8, protected, path)) {
                return true;
            }
        }
        return false;
    }
};

pub fn init(self: *Self, cache_path: []const u8, cache_key: []const u8, source_avio_ctx: [*c]c.AVIOContext) !void {
    if (self.has_been_open.load(.seq_cst)) {
        return;
    }

    std.debug.assert(fs.path.isAbsolute(cache_path));

    self.source_avio_ctx = source_avio_ctx;

    const sanitize_cache_key = try sanitizeForPath(self.allocator, cache_key);
    defer self.allocator.free(sanitize_cache_key);

    self.cache_directory = try fs.path.join(self.allocator, &[_][]const u8{
        cache_path,
        sanitize_cache_key,
    });
    errdefer self.allocator.free(self.cache_directory);

    try self.protected_opened_cache_paths.protectPath(self.cache_directory);
    errdefer self.protected_opened_cache_paths.unprotectPath(self.cache_directory);

    try makeRecursiveDirAbsolute(self.cache_directory);

    const data_file_path = try fs.path.join(self.allocator, &[_][]const u8{
        self.cache_directory,
        DATA_FILE,
    });
    defer self.allocator.free(data_file_path);

    self.data_file = try fs.createFileAbsolute(data_file_path, .{
        .read = true,
        .truncate = false,
    });
    errdefer self.data_file.close();

    const index_file_path = try fs.path.join(self.allocator, &[_][]const u8{
        self.cache_directory,
        INDEX_FILE,
    });
    defer self.allocator.free(index_file_path);

    self.index_file = try fs.createFileAbsolute(index_file_path, .{
        .read = true,
        .truncate = false,
    });
    errdefer self.index_file.close();

    try self.index_file.updateTimes(std.time.nanoTimestamp(), std.time.nanoTimestamp());

    try Self.checkAndCleanOldCaches(self.allocator, cache_path, self.protected_opened_cache_paths);

    try self.index_file.seekFromEnd(0);
    self.index_size = @intCast(try self.index_file.getPos());
    try self.index_file.seekTo(0);

    if (self.index_size >= 8) {
        _ = try self.index_file.readAll(std.mem.asBytes(&self.file_total_size));
        self.index_size -= @sizeOf(u64);
    } else {
        self.file_total_size = 0;
    }

    if (self.file_total_size == 0) {
        try self.index_file.seekTo(0);

        const file_size = c.avio_size(self.source_avio_ctx);

        if (file_size < 0) {
            return error.CantGetAVIOFileSize;
        }

        self.file_total_size = @intCast(file_size);
        _ = try self.index_file.write(std.mem.asBytes(&self.file_total_size));
    }

    try self.index_map.resize(self.index_size);
    const bytes_read = try self.index_file.readAll(self.index_map.items);
    @memset(self.index_map.items[bytes_read..], 0);

    self.current_offset = 0;
    var buffer: [*c]u8 = @ptrCast(@alignCast(c.av_malloc(BUFFER_SIZE)));

    self.avio_ctx = c.avio_alloc_context(buffer, BUFFER_SIZE, 0, self, &Self.customReadPacket, null, &Self.customSeek) orelse {
        c.av_freep(@ptrCast(&buffer));

        std.log.err("Could not open custom AVIOContext\n", .{});
        return error.CouldNotOpenCustomAVIOContext;
    };

    self.has_been_open.store(true, .seq_cst);
}

pub fn deinit(self: *Self) void {
    if (!self.has_been_open.load(.seq_cst)) {
        return;
    }

    var buffer = self.avio_ctx.*.buffer;

    c.avio_context_free(@ptrCast(&self.avio_ctx));

    c.av_freep(@ptrCast(&buffer));

    self.data_file.close();
    self.index_file.close();

    self.protected_opened_cache_paths.unprotectPath(self.cache_directory);

    self.allocator.free(self.cache_directory);

    self.has_been_open.store(false, .seq_cst);
}

pub fn evictCache(self: *Self) !void {
    if (!self.has_been_open.load(.seq_cst)) {
        return;
    }

    const cache_directory = try self.allocator.dupe(u8, self.cache_directory);
    defer self.allocator.free(cache_directory);

    self.deinit();

    try deleteDirectoryRecursive(self.allocator, cache_directory);
}

pub fn resetAVIOError(self: *Self) void {
    if (!self.has_been_open.load(.seq_cst)) {
        return;
    }

    self.avio_ctx.@"error" = 0;
    self.avio_ctx.eof_reached = 0;
}

fn isBlockCached(self: *Self, block_id: u64) bool {
    if (block_id * BLOCK_SIZE >= self.file_total_size) {
        return true;
    }

    const byte_index = block_id / 8;
    if (byte_index >= self.index_size)
        return false;

    return (self.index_map.items[@intCast(byte_index)] >> @intCast(block_id % 8)) & 1 == 1;
}

fn markBlockAsCached(self: *Self, block_id: u64) !void {
    if (block_id < 0) {
        return;
    }

    if (block_id * BLOCK_SIZE >= self.file_total_size) {
        return;
    }

    const byte_index = block_id / 8;
    const bit_index = block_id % 8;

    if (byte_index >= self.index_size) {
        const old_len = self.index_map.items.len;
        try self.index_map.resize(@intCast(byte_index + 1));
        @memset(self.index_map.items[old_len..], 0);
        self.index_size = self.index_map.items.len;
    }

    self.index_map.items[@intCast(byte_index)] |= switch (bit_index) {
        0 => 1 << 0,
        1 => 1 << 1,
        2 => 1 << 2,
        3 => 1 << 3,
        4 => 1 << 4,
        5 => 1 << 5,
        6 => 1 << 6,
        7 => 1 << 7,
        else => 0,
    };

    _ = self.isBlockCached(block_id);

    try self.index_file.seekTo(byte_index + @sizeOf(u64));

    _ = try self.index_file.write(&.{self.index_map.items[@intCast(byte_index)]});
}

fn downloadBlock(self: *Self, block_id: u64) !void {
    if (self.isBlockCached(block_id)) {
        return;
    }

    var buffer: [BLOCK_SIZE]u8 = [_]u8{0} ** BLOCK_SIZE;
    var offset = block_id * BLOCK_SIZE;
    _ = c.avio_seek(self.source_avio_ctx, @intCast(offset), c.SEEK_SET);

    var wanted: c_int = BLOCK_SIZE;

    while (wanted > 0) {
        const bytes_read = c.avio_read(self.source_avio_ctx, @ptrCast(&buffer), wanted);

        if (bytes_read == c.AVERROR_EOF) {
            try self.markBlockAsCached(block_id);
            return;
        }

        if (bytes_read == c.AVERROR(c.ETIMEDOUT)) {
            return error.SourceTimeout;
        }

        if (bytes_read < 0) {
            return error.CouldNotReadSourceAVIO;
        }

        if (bytes_read != 0) {
            try self.data_file.seekTo(offset);

            _ = try self.data_file.write(buffer[0..@intCast(bytes_read)]);
        }

        wanted -= bytes_read;
        offset += @intCast(bytes_read);
    }

    try self.markBlockAsCached(block_id);
}

fn customReadPacket(opaqued: ?*anyopaque, buf: [*c]u8, buf_size: c_int) callconv(.c) c_int {
    const self: *Self = @ptrCast(@alignCast(opaqued));

    const start_block = @divTrunc(self.current_offset, BLOCK_SIZE);
    const end_block = @divTrunc(self.current_offset + @as(u64, @intCast(buf_size)), BLOCK_SIZE) + 2;

    var block_id = start_block;
    while (block_id <= end_block) : (block_id += 1) {
        if (block_id >= 0) {
            self.downloadBlock(block_id) catch |err| {
                if (err == error.SourceTimeout) {
                    return c.AVERROR(c.ETIMEDOUT);
                }
                std.log.warn("Could not read packet {}", .{err});
                return 0;
            };
        }
    }

    self.data_file.seekTo(self.current_offset) catch |err| {
        std.log.warn("Could not read packet {}", .{err});
        return 0;
    };

    const bytes_read = self.data_file.read(buf[0..@intCast(buf_size)]) catch |err| {
        std.log.warn("Could not read packet {}", .{err});
        return 0;
    };

    if (bytes_read <= 0)
        return c.AVERROR_EOF;

    self.current_offset += bytes_read;

    return @intCast(bytes_read);
}

fn customSeek(opaqued: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) i64 {
    const self: *Self = @ptrCast(@alignCast(opaqued));

    var new_offset: u64 = undefined;

    if (whence == c.SEEK_SET) {
        new_offset = @intCast(offset);
    } else if (whence == c.SEEK_CUR) {
        new_offset = self.current_offset + @as(u64, @intCast(offset));
    } else if (whence == c.SEEK_END) {
        new_offset = self.file_total_size - @as(u64, @intCast(offset));
    } else if (whence == c.AVSEEK_SIZE) {
        return @intCast(self.file_total_size);
    } else {
        return -1;
    }

    self.current_offset = new_offset;

    return c.avio_seek(self.source_avio_ctx, 0, c.SEEK_CUR);
}

// av_err2str returns a temporary array. This doesn't work in gcc.
// This function can be used as a replacement for av_err2str.
fn getAVError(_: *Self, errnum: c_int) *const [c.AV_ERROR_MAX_STRING_SIZE:0]u8 {
    const state = struct {
        var error_message: [c.AV_ERROR_MAX_STRING_SIZE:0]u8 = undefined;
    };

    _ = c.av_make_error_string(&state.error_message, c.AV_ERROR_MAX_STRING_SIZE, errnum);

    return &state.error_message;
}

fn makeRecursiveDirAbsolute(path: []const u8) !void {
    std.debug.assert(fs.path.isAbsolute(path));

    var pos: ?usize = 0;

    pos = std.mem.indexOfScalarPos(u8, path, pos.?, fs.path.sep);
    while (pos != null) : (pos = std.mem.indexOfScalarPos(u8, path, pos.? + 1, fs.path.sep)) {
        const sub_path = path[0..pos.?];

        if (sub_path.len == 0) {
            continue;
        }

        fs.accessAbsolute(sub_path, .{}) catch {
            try fs.makeDirAbsolute(sub_path);
        };
    }

    fs.accessAbsolute(path, .{}) catch {
        try fs.makeDirAbsolute(path);
    };
}

fn sanitizeForPath(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    const forbiddenChars = "\\/:*?\"<>| ";

    var sanitized = try allocator.alloc(u8, text.len);
    errdefer allocator.free(sanitized);

    // UTF8 String may have variable size but they are compatible ASCII
    // We only want to remove invalid ASCII character by replacing them with ASCII
    // So we don't need to filter at the code points level
    for (0.., text) |i, char| {
        if ((!std.ascii.isAlphanumeric(char) and std.mem.indexOfScalar(u8, forbiddenChars, char) != null)) {
            sanitized[i] = '_';
        } else {
            sanitized[i] = char;
        }
    }

    return sanitized;
}

fn checkAndCleanOldCaches(allocator: std.mem.Allocator, cache_path: []const u8, protected_opened_cache_paths: *ProtectedOpenedPathsList) !void {
    clean_cache_mutex.lock();
    defer clean_cache_mutex.unlock();

    var directory_size = try getDirectorySize(allocator, cache_path);

    while (directory_size >= CACHE_MAX_SIZE_DIRECTORY) {
        const oldest_path = try findOldestFileByName(allocator, cache_path, INDEX_FILE);

        if (oldest_path == null) {
            std.log.warn("There is no cache to delete, system is low on storage space", .{});
            break;
        }

        defer allocator.free(oldest_path.?);

        const parent_directory = fs.path.dirname(oldest_path.?);

        if (parent_directory == null) {
            std.log.warn("Wait there is no parent really ?", .{});
            break;
        }

        if (protected_opened_cache_paths.isPathProtect(parent_directory.?)) {
            std.log.warn("We need to wait until deleting the oldest cache to free up some space", .{});
            return;
        }

        try deleteDirectoryRecursive(allocator, parent_directory.?);

        directory_size = try getDirectorySize(allocator, cache_path);
    }
}

fn deleteDirectoryRecursive(allocator: std.mem.Allocator, dir_path: []const u8) !void {
    var dir = try fs.openDirAbsolute(dir_path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        const full_entry_path = try fs.path.join(allocator, &.{ dir_path, entry.name });
        switch (entry.kind) {
            .sym_link, .file => {
                try fs.deleteFileAbsolute(full_entry_path);
            },
            .directory => {
                try deleteDirectoryRecursive(allocator, full_entry_path);
            },
            else => {},
        }
    }

    try fs.deleteDirAbsolute(dir_path);
}

fn findOldestFileByName(allocator: std.mem.Allocator, directory: []const u8, search_file_name: []const u8) !?[]const u8 {
    var oldest_file: ?[]const u8 = null;

    errdefer if (oldest_file != null) {
        allocator.free(oldest_file.?);
    };

    var oldest_time: i128 = std.math.maxInt(i128);
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const al = arena.allocator();

    var dir = try fs.openDirAbsolute(directory, .{ .iterate = true });
    defer dir.close();

    var iterator = dir.iterate();

    while (try iterator.next()) |entry| {
        const subpath = fs.path.join(al, &.{ directory, entry.name }) catch continue;

        if (entry.kind == .file) {
            const time = try getFieMtime(subpath);

            const file = try fs.openFileAbsolute(subpath, .{});
            defer file.close();

            if (std.mem.eql(u8, entry.name, search_file_name) and time < oldest_time) {
                oldest_time = time;
                if (oldest_file != null) {
                    allocator.free(oldest_file.?);
                }
                oldest_file = try std.fmt.allocPrint(allocator, "{s}", .{subpath});
            }
        } else if (entry.kind == .directory and !std.mem.eql(u8, entry.name, ".") and !std.mem.eql(u8, entry.name, "..")) {
            const result = try findOldestFileByName(allocator, subpath, search_file_name);
            if (result == null) {
                continue;
            }

            const time = try getFieMtime(subpath);

            const file = try fs.openFileAbsolute(result.?, .{});
            defer file.close();

            if (time < oldest_time) {
                oldest_time = time;
                if (oldest_file != null) {
                    allocator.free(oldest_file.?);
                }
                oldest_file = result.?;
            } else {
                allocator.free(result.?);
            }
        }
    }

    return oldest_file;
}

fn getFileSize(path: []const u8) !u64 {
    const file = try fs.openFileAbsolute(path, .{});
    defer file.close();

    if (builtin.abi.isAndroid()) {
        const st = try std.posix.fstat(file.handle);
        return std.fs.File.Stat.fromPosix(st).size;
    }

    const stat = try file.stat();
    return stat.size;
}

fn getFieMtime(path: []const u8) !i128 {
    const file = try fs.openFileAbsolute(path, .{});
    defer file.close();

    if (builtin.abi.isAndroid()) {
        const st = try std.posix.fstat(file.handle);
        return std.fs.File.Stat.fromPosix(st).mtime;
    }

    const stat = try file.stat();
    return stat.mtime;
}

fn getDirectorySize(allocator: std.mem.Allocator, path: []const u8) !u64 {
    var total_size: u64 = 0;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const al = arena.allocator();

    var dir = try fs.openDirAbsolute(path, .{ .iterate = true });
    defer dir.close();

    var iterator = dir.iterate();
    while (try iterator.next()) |entry| {
        const subpath = fs.path.join(al, &.{ path, entry.name }) catch continue;

        if (entry.kind == .file) {
            total_size += try getFileSize(subpath);
        } else if (entry.kind == .directory and !std.mem.eql(u8, entry.name, ".") and !std.mem.eql(u8, entry.name, "..")) {
            total_size += try getDirectorySize(allocator, subpath);
        }
    }

    return total_size;
}
