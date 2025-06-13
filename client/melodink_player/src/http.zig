const builtin = @import("builtin");

const std = @import("std");

const c = @import("c.zig");

const Self = @This();

const BUFFER_SIZE = 4096;

allocator: std.mem.Allocator,
has_been_open: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
should_deinit: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
options: ?*c.AVDictionary = null,

is_reopen: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

file_url: [:0]const u8 = undefined,

current_offset: i64 = 0,
file_total_size: u64 = 0,

source_avio_ctx: [*c]c.AVIOContext = undefined,
avio_ctx: *c.AVIOContext = undefined,

has_been_open_http: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

thread: ?std.Thread = null,

pub fn init(self: *Self, url: [:0]const u8, new_options: [*c]?*c.AVDictionary) !void {
    if (self.has_been_open.load(.seq_cst)) {
        return;
    }

    self.file_url = try std.fmt.allocPrintZ(self.allocator, "{s}", .{url});
    errdefer self.allocator.free(self.file_url);

    _ = c.av_dict_copy(&self.options, new_options.*, 0);

    var buffer: [*c]u8 = @ptrCast(@alignCast(c.av_malloc(BUFFER_SIZE)));

    self.avio_ctx = c.avio_alloc_context(buffer, BUFFER_SIZE, 0, self, &Self.customReadPacket, null, &Self.customSeek) orelse {
        c.av_freep(@ptrCast(&buffer));
        self.closeHTTP();

        std.log.err("Could not open custom AVIOContext\n", .{});
        return error.CouldNotOpenCustomAVIOContext;
    };

    self.current_offset = 0;
    self.has_been_open.store(true, .seq_cst);
    self.is_reopen.store(false, .seq_cst);
}

pub fn deinit(self: *Self) void {
    if (!self.has_been_open.load(.seq_cst)) {
        return;
    }

    self.should_deinit.store(true, .seq_cst);

    if (self.thread != null) {
        self.thread.?.join();
    }

    self.should_deinit.store(false, .seq_cst);

    var buffer = self.avio_ctx.*.buffer;

    c.avio_context_free(@ptrCast(&self.avio_ctx));
    self.closeHTTP();

    c.av_freep(@ptrCast(&buffer));

    self.allocator.free(self.file_url);

    self.has_been_open.store(false, .seq_cst);
}

pub fn resetAVIOError(self: *Self) void {
    if (!self.has_been_open.load(.seq_cst)) {
        return;
    }

    self.avio_ctx.@"error" = 0;
    self.avio_ctx.eof_reached = 0;
}

fn openHTTP(self: *Self) !void {
    if (self.has_been_open_http.load(.seq_cst)) {
        return;
    }

    var loptions: ?*c.AVDictionary = null;
    _ = c.av_dict_copy(&loptions, self.options, 0);

    const response = c.avio_open2(&self.source_avio_ctx, self.file_url, c.AVIO_FLAG_READ | c.AVIO_FLAG_NONBLOCK, null, &loptions);
    if (response < 0) {
        std.log.err("Could not open AVIOContext: {s}\n", .{self.getAVError(response)});
        return error.CouldNotOpenAVIOContext;
    }
    self.file_total_size = @intCast(c.avio_size(self.source_avio_ctx));
    self.has_been_open_http.store(true, .seq_cst);
}

fn closeHTTP(self: *Self) void {
    if (!self.has_been_open_http.load(.seq_cst)) {
        return;
    }
    _ = c.avio_closep(&self.source_avio_ctx);
    self.has_been_open_http.store(false, .seq_cst);
}

fn reopenHTTP(self: *Self) void {
    defer self.is_reopen.store(false, .seq_cst);

    self.closeHTTP();

    while (true) {
        if (self.should_deinit.load(.seq_cst)) {
            return;
        }

        self.openHTTP() catch |err| {
            std.log.warn("Could not reopen HTTP {}", .{err});
            std.time.sleep(std.time.ns_per_s);
            continue;
        };
        break;
    }
}

fn handleError(self: *Self, status: c_int) c_int {
    if (status != c.AVERROR_EOF) {
        if (self.is_reopen.load(.seq_cst)) {
            return c.AVERROR(c.ETIMEDOUT);
        }

        self.is_reopen.store(true, .seq_cst);

        if (self.thread != null) {
            self.thread.?.join();
        }

        self.thread = std.Thread.spawn(.{}, reopenHTTP, .{self}) catch |err| {
            self.thread = null;
            std.log.warn("Failed to start reopenHTTP thread {}", .{err});

            self.is_reopen.store(false, .seq_cst);

            return status;
        };

        return c.AVERROR(c.ETIMEDOUT);
    }

    return status;
}

fn customReadPacket(opaqued: ?*anyopaque, buf: [*c]u8, buf_size: c_int) callconv(.c) c_int {
    const self: *Self = @ptrCast(@alignCast(opaqued));

    if (self.is_reopen.load(.seq_cst)) {
        return c.AVERROR(c.ETIMEDOUT);
    }

    self.openHTTP() catch |err| {
        std.log.warn("Could not open HTTP {}", .{err});
        return c.AVERROR(c.ETIMEDOUT);
    };

    const seek = c.avio_seek(self.source_avio_ctx, self.current_offset, c.SEEK_SET);

    if (seek < 0) {
        return self.handleError(@intCast(seek));
    }

    const bytes_read = c.avio_read(self.source_avio_ctx, buf, buf_size);

    if (bytes_read < 0) {
        return self.handleError(bytes_read);
    }

    self.current_offset += bytes_read;

    return bytes_read;
}

fn customSeek(opaqued: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) i64 {
    const self: *Self = @ptrCast(@alignCast(opaqued));

    if (self.is_reopen.load(.seq_cst)) {
        return c.AVERROR(c.ETIMEDOUT);
    }

    self.openHTTP() catch |err| {
        std.log.warn("Could not open HTTP {}", .{err});
        return c.AVERROR(c.ETIMEDOUT);
    };

    var new_offset: i64 = undefined;

    if (whence == c.SEEK_SET) {
        new_offset = @intCast(offset);
    } else if (whence == c.SEEK_CUR) {
        new_offset = self.current_offset + offset;
    } else if (whence == c.SEEK_END) {
        new_offset = @as(i64, @intCast(self.file_total_size)) - offset;
    } else if (whence == c.AVSEEK_SIZE) {
        return @intCast(self.file_total_size);
    } else {
        return -1;
    }

    self.current_offset = new_offset;
    return 0;
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
