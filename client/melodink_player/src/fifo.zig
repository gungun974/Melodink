const std = @import("std");

const Thread = std.Thread;

const c = @import("c.zig");

const Self = @This();

mutex: Thread.Mutex = Thread.Mutex{},
av_fifo: ?*c.AVAudioFifo = null,

pub fn init(self: *Self, format: c.AVSampleFormat, channels: u64, init_capacity: u64) !void {
    self.mutex.lock();
    defer self.mutex.unlock();

    if ((init_capacity == 0) or (channels == 0)) {
        return error.InvalidArgs;
    }

    if (self.av_fifo != null) {
        if (self.av_fifo != null) {
            _ = c.av_audio_fifo_drain(self.av_fifo, c.av_audio_fifo_size(self.av_fifo));
        }

        c.av_audio_fifo_free(self.av_fifo);
        self.av_fifo = null;
    }

    self.av_fifo = c.av_audio_fifo_alloc(format, @intCast(channels), @intCast(init_capacity));

    if (self.av_fifo == null) {
        return error.CouldNotAllocFifo;
    }
}

pub fn push(self: *Self, data: [*c]const ?*anyopaque, samples: u64) !u64 {
    self.mutex.lock();
    defer self.mutex.unlock();

    if (self.av_fifo == null) {
        return error.FifoIsNotInit;
    }

    const space = c.av_audio_fifo_space(self.av_fifo);

    if (samples > space) {
        _ = c.av_audio_fifo_drain(self.av_fifo, @min(c.av_audio_fifo_size(self.av_fifo), @as(c_int, @intCast(samples)) - space));
    }

    return @intCast(c.av_audio_fifo_write(self.av_fifo, data, @intCast(samples)));
}

pub fn pop(self: *Self, data: [*c]?*anyopaque, samples: u64) !u64 {
    self.mutex.lock();
    defer self.mutex.unlock();

    if (self.av_fifo == null) {
        return error.FifoIsNotInit;
    }

    return @intCast(c.av_audio_fifo_read(self.av_fifo, data, @intCast(samples)));
}

pub fn drain(self: *Self, samples: u64) void {
    self.mutex.lock();
    defer self.mutex.unlock();

    if (self.av_fifo == null) {
        return;
    }

    _ = c.av_audio_fifo_drain(self.av_fifo, @intCast(samples));
}

pub fn size(self: *Self) u64 {
    self.mutex.lock();
    defer self.mutex.unlock();

    if (self.av_fifo == null) {
        return 0;
    }

    return @intCast(c.av_audio_fifo_size(self.av_fifo));
}

pub fn capacity(self: *Self) u64 {
    self.mutex.lock();
    defer self.mutex.unlock();

    if (self.av_fifo == null) {
        return 0;
    }

    return @intCast(c.av_audio_fifo_space(self.av_fifo) + c.av_audio_fifo_size(self.av_fifo));
}

pub fn clear(self: *Self) void {
    self.mutex.lock();
    defer self.mutex.unlock();

    if (self.av_fifo != null) {
        _ = c.av_audio_fifo_drain(self.av_fifo, c.av_audio_fifo_size(self.av_fifo));
    }
}

pub fn free(self: *Self) void {
    self.mutex.lock();
    defer self.mutex.unlock();

    if (self.av_fifo == null) {
        return;
    }

    c.av_audio_fifo_free(self.av_fifo);
    self.av_fifo = null;
}

pub fn available(self: *Self) bool {
    self.mutex.lock();
    defer self.mutex.unlock();

    return self.av_fifo != null;
}
