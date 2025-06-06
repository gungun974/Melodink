const builtin = @import("builtin");

const std = @import("std");

const c = @import("c.zig");

const Self = @This();

const BUFFER_SIZE = 4096;

allocator: std.mem.Allocator,
has_been_open: bool = false,
options: ?*c.AVDictionary = null,

file_url: [:0]const u8 = undefined,

source_avio_ctx: [*c]c.AVIOContext = undefined,
avio_ctx: *c.AVIOContext = undefined,

has_been_open_http: bool = false,

pub fn init(self: *Self, url: [:0]const u8, new_options: [*c]?*c.AVDictionary) !void {
    if (self.has_been_open) {
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

    self.has_been_open = true;
}

pub fn deinit(self: *Self) void {
    if (!self.has_been_open) {
        return;
    }

    var buffer = self.avio_ctx.*.buffer;

    c.avio_context_free(@ptrCast(&self.avio_ctx));
    self.closeHTTP();

    c.av_freep(@ptrCast(&buffer));

    self.allocator.free(self.file_url);

    self.has_been_open = false;
}

fn openHTTP(self: *Self) !void {
    if (self.has_been_open_http) {
        return;
    }

    var loptions: ?*c.AVDictionary = null;
    _ = c.av_dict_copy(&loptions, self.options, 0);

    const response = c.avio_open2(&self.source_avio_ctx, self.file_url, c.AVIO_FLAG_READ | c.AVIO_FLAG_NONBLOCK, null, &loptions);
    if (response < 0) {
        std.log.err("Could not open AVIOContext: {s}\n", .{self.getAVError(response)});
        return error.CouldNotOpenAVIOContext;
    }
    self.has_been_open_http = true;
}

fn closeHTTP(self: *Self) void {
    if (!self.has_been_open_http) {
        return;
    }
    _ = c.avio_closep(&self.source_avio_ctx);
    self.has_been_open_http = false;
}

fn customReadPacket(opaqued: ?*anyopaque, buf: [*c]u8, buf_size: c_int) callconv(.c) c_int {
    const self: *Self = @ptrCast(@alignCast(opaqued));

    self.openHTTP() catch |err| {
        std.log.warn("Could not open HTTP {}", .{err});
        return 0;
    };

    const bytes_read = c.avio_read(self.source_avio_ctx, buf, buf_size);

    return bytes_read;
}

fn customSeek(opaqued: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) i64 {
    const self: *Self = @ptrCast(@alignCast(opaqued));

    self.openHTTP() catch |err| {
        std.log.warn("Could not open HTTP {}", .{err});
        return 0;
    };

    return c.avio_seek(self.source_avio_ctx, offset, whence);
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
