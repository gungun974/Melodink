const std = @import("std");

const Self = @This();

const Channel = struct { z1: f64 = 0, z2: f64 = 0 };
const Biquad = struct {
    a0: f64,
    a1: f64,
    a2: f64,
    b0: f64,
    b1: f64,
    b2: f64,
    channels: []Channel = undefined,

    fn calcBellRLC(self: *Biquad, freq: f64, Q: f64, gain_dB: f64, sample_rate: u64) void {
        const a = std.math.pow(f64, 10.0, gain_dB / 40.0);
        const omega = 2.0 * std.math.pi * freq / @as(f64, @floatFromInt(sample_rate));
        const alpha = std.math.sin(omega) / (2.0 * Q);
        const cos_omega = std.math.cos(omega);

        self.b0 = 1 + alpha * a;
        self.b1 = -2 * cos_omega;
        self.b2 = 1 - alpha * a;
        self.a0 = 1 + alpha / a;
        self.a1 = -2 * cos_omega;
        self.a2 = 1 - alpha / a;

        // Normalisation
        const a0_inv = 1.0 / self.a0;
        self.b0 *= a0_inv;
        self.b1 *= a0_inv;
        self.b2 *= a0_inv;
        self.a1 *= a0_inv;
        self.a2 *= a0_inv;
    }

    fn process(self: *Biquad, input: f64, ch: usize) f64 {
        const output = self.b0 * input + self.channels[ch].z1;
        self.channels[ch].z1 = self.b1 * input - self.a1 * output + self.channels[ch].z2;
        self.channels[ch].z2 = self.b2 * input - self.a2 * output;

        return output;
    }
};

mutex: std.Thread.Mutex = std.Thread.Mutex{},

allocator: std.mem.Allocator,

bands: std.ArrayListUnmanaged(Biquad) = std.ArrayListUnmanaged(Biquad){},

enable: bool = undefined,
frequencies: std.ArrayListUnmanaged(f64) = std.ArrayListUnmanaged(f64){},
gains: std.ArrayListUnmanaged(f64) = std.ArrayListUnmanaged(f64){},

pub fn setSetting(self: *Self, enable: bool, frequencies: []const f64, gains: []const f64) !void {
    self.mutex.lock();
    defer self.mutex.unlock();

    self.enable = enable;

    try self.frequencies.resize(self.allocator, frequencies.len);
    @memcpy(self.frequencies.items, frequencies);

    try self.gains.resize(self.allocator, gains.len);
    @memcpy(self.gains.items, gains);
}

pub fn init(self: *Self, channel_count: u64, sample_rate: u64) !void {
    self.mutex.lock();
    defer self.mutex.unlock();

    try self.bands.resize(self.allocator, self.frequencies.items.len);

    for (0..self.bands.items.len) |i| {
        self.bands.items[i].channels = try self.allocator.alloc(Channel, @intCast(channel_count));
        errdefer self.allocator.free(self.bands.items[i].channels);
    }

    const q = 0.96;

    for (0..self.bands.items.len) |i| {
        @memset(self.bands.items[i].channels, Channel{});

        self.bands.items[i].calcBellRLC(self.frequencies.items[i], q, self.gains.items[i], sample_rate);
    }
}

pub fn deinit(self: *Self) void {
    self.mutex.lock();
    defer self.mutex.unlock();

    for (0..self.bands.items.len) |i| {
        self.allocator.free(self.bands.items[i].channels);
    }
}

pub fn free(self: *Self) void {
    self.frequencies.clearAndFree(self.allocator);
    self.gains.clearAndFree(self.allocator);
    self.bands.clearAndFree(self.allocator);
}

fn processF64(self: *Self, input: f64, ch: usize) f64 {
    if (@TypeOf(input) != f64) {
        @compileError("Can't convert sample for equalizer");
    }

    var out = input;
    for (0..self.bands.items.len) |i| {
        out = self.bands.items[i].process(out, ch);
    }
    return out;
}

pub fn process(self: *Self, input: anytype, ch: usize) @TypeOf(input) {
    self.mutex.lock();
    defer self.mutex.unlock();

    return switch (@TypeOf(input)) {
        f64 => self.processF64(input, ch),
        f32 => @floatCast(self.processF64(@floatCast(input), ch)),
        i16 => f64ToS16(self.processF64(s16ToF64(input), ch)),
        i24 => f64ToS24(self.processF64(s24ToF64(input), ch)),
        i32 => f64ToS32(self.processF64(s32ToF64(input), ch)),
        u8 => f64ToU8(self.processF64(u8ToF64(input), ch)),
        else => @compileError("Can't convert sample for equalizer"),
    };
}

fn f64ToS16(sample: f64) i16 {
    const clamped = std.math.clamp(sample, -1.0, 1.0);

    return @intCast(@as(i32, @intFromFloat(clamped * 32767.0)));
}

fn s16ToF64(sample: i16) f64 {
    return @as(f64, @floatFromInt(sample)) * (1.0 / 32768.0);
}

fn f64ToS24(sample: f64) i24 {
    const clamped = std.math.clamp(sample, -1.0, 1.0);

    return @intCast(@as(i24, @intFromFloat(clamped * 8388607.0)));
}

fn s24ToF64(sample: i24) f64 {
    return @as(f64, @floatFromInt(sample)) * (1.0 / 8388608.0);
}

fn f64ToS32(sample: f64) i32 {
    const clamped = std.math.clamp(sample, -1.0, 1.0);

    return @intCast(@as(i32, @intFromFloat(clamped * 2147483647.0)));
}

fn s32ToF64(sample: i32) f64 {
    return @as(f64, @floatFromInt(sample)) * (1.0 / 2147483648.0);
}

fn f64ToU8(sample: f64) u8 {
    const clamped = std.math.clamp(sample, -1.0, 1.0);
    return @intCast(@as(u8, @intFromFloat((clamped * 127.5) + 127.5)));
}

fn u8ToF64(sample: u8) f64 {
    return (@as(f64, @floatFromInt(sample)) - 127.5) * (1.0 / 127.5);
}
