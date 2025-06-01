const std = @import("std");

const Thread = std.Thread;

const c = @import("c.zig");

const TrackMod = @import("track.zig");

const Equalizer = @import("equalizer.zig");

const Track = TrackMod.Track;
const TrackQuality = TrackMod.TrackQuality;
const TrackStatus = TrackMod.TrackStatus;

const TrackManager = struct {
    const Self = @This();

    const IndexedTrack = struct {
        const IndexedSelf = @This();

        track: *Track,

        index: usize,

        tracks_order: *TrackArrayList,

        fn next(self: IndexedSelf) ?IndexedTrack {
            const next_index = self.index + 1;
            if (next_index >= self.tracks_order.items.len) {
                return null;
            }
            return self.tracks_order.items[next_index];
        }

        fn previous(self: IndexedSelf) ?IndexedTrack {
            if (self.index <= 0) {
                return null;
            }
            return self.tracks_order.items[self.index - 1];
        }

        fn first(self: IndexedSelf) IndexedTrack {
            return self.tracks_order.items[0];
        }
    };

    const TrackArrayList = std.ArrayList(IndexedTrack);
    const TrackAutoHashMap = std.AutoHashMap(u64, *Track);

    const CacheAVIO = @import("cache.zig");

    current_track_mutex: Thread.Mutex = Thread.Mutex{},

    allocator: std.mem.Allocator,

    manage_tracks_order: TrackArrayList,
    manage_loaded_tracks: TrackAutoHashMap,

    current_track_index: ?usize = 0,

    protected_opened_cache_paths: CacheAVIO.ProtectedOpenedPathsList,

    pub fn getCurrentIndexedTrack(self: *const Self) ?IndexedTrack {
        if (self.current_track_index == null or self.current_track_index.? >= self.manage_tracks_order.items.len) {
            return null;
        }
        return self.manage_tracks_order.items[self.current_track_index.?];
    }

    pub fn setCurrentIndexedTrack(self: *Self, indexed_track: ?IndexedTrack) void {
        self.current_track_mutex.lock();
        defer self.current_track_mutex.unlock();
        self.current_track_index = if (indexed_track != null) indexed_track.?.index else null;
    }

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,

            .manage_tracks_order = TrackArrayList.init(allocator),
            .manage_loaded_tracks = TrackAutoHashMap.init(allocator),

            .protected_opened_cache_paths = CacheAVIO.ProtectedOpenedPathsList.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var iterator = self.manage_loaded_tracks.iterator();

        while (iterator.next()) |track| {
            track.value_ptr.*.free();
        }

        self.manage_tracks_order.deinit();
        self.manage_loaded_tracks.deinit();

        self.protected_opened_cache_paths.deinit();
    }

    fn freeTrack(self: *Self, track: *Track) void {
        track.*.free();
        self.allocator.destroy(track);
    }

    fn compareStrings(a: ?[]const u8, b: ?[]const u8) bool {
        if (a == null and b == null) return true;
        if (a == null or b == null) return false;
        return std.mem.eql(u8, a.?, b.?);
    }

    pub fn loads(self: *Self, play_request_index: usize, requests: []const MelodinkTrackRequest, quality: TrackQuality, server_auth: []const u8) !void {
        if (self.current_track_index != null) {}
        try self.manage_tracks_order.resize(requests.len);

        // unload old tracks
        var iterator = self.manage_loaded_tracks.iterator();
        var tracksToRemove = std.ArrayList(u64).init(self.allocator);
        defer tracksToRemove.deinit();

        while (iterator.next()) |track| {
            var keep = false;
            for (requests) |request| {
                if (track.value_ptr.*.id != request.id) {
                    continue;
                }

                if (!compareStrings(request.original_audio_hash, track.value_ptr.*.original_audio_hash)) {
                    break;
                }

                if (!compareStrings(request.downloaded_path, track.value_ptr.*.downloaded_path)) {
                    break;
                }

                keep = true;
                break;
            }

            if (!keep) {
                try tracksToRemove.append(track.value_ptr.*.id);
            }
        }

        for (tracksToRemove.items) |id| {
            const trackToRemove = self.manage_loaded_tracks.getPtr(id);

            if (self.getCurrentIndexedTrack() != null and self.getCurrentIndexedTrack().?.track.id == id) {
                self.setCurrentIndexedTrack(null);
            }

            if (trackToRemove.?.*.open_thread or trackToRemove.?.*.status != TrackStatus.idle) {
                const thread = try Thread.spawn(.{}, TrackManager.freeTrack, .{ self, trackToRemove.?.* });
                thread.detach();
            } else {
                self.freeTrack(trackToRemove.?.*);
            }

            _ = self.manage_loaded_tracks.remove(id);
        }

        // load new tracks
        for (requests) |request| {
            if (!self.manage_loaded_tracks.contains(request.id)) {
                const new_track = try self.allocator.create(Track);
                errdefer self.allocator.destroy(new_track);

                new_track.* = try Track.new(self.allocator, request.id, quality, request.server_url, request.downloaded_path, request.original_audio_hash, request.cache_path, server_auth, &self.protected_opened_cache_paths);

                try self.manage_loaded_tracks.put(request.id, new_track);
            }
        }

        // set every order

        for (0.., requests) |i, request| {
            self.manage_tracks_order.items[i] = .{
                .index = i,
                .track = self.manage_loaded_tracks.getPtr(request.id).?.*,

                .tracks_order = &self.manage_tracks_order,
            };
        }

        self.manage_tracks_order.items.len = requests.len;

        // set current track

        if (requests.len > 0) {
            if (self.getCurrentIndexedTrack() != null and self.getCurrentIndexedTrack().?.track.id != self.manage_tracks_order.items[play_request_index].track.id) {
                self.getCurrentIndexedTrack().?.track.need_reset = true;
            }

            self.setCurrentIndexedTrack(self.manage_tracks_order.items[play_request_index]);
        }

        // every other tracks should have a playback ready from start

        var iterator2 = self.manage_loaded_tracks.iterator();

        while (iterator2.next()) |track| {
            if (requests.len > 0 and track.value_ptr.*.id == self.getCurrentIndexedTrack().?.track.id) {
                continue;
            }

            if (track.value_ptr.*.getCurrentPlaybackTime() != 0) {
                track.value_ptr.*.need_reset = true;
            }
        }
    }

    pub fn swapTracksQuality(self: *Self, quality: TrackQuality, perform_hot_swap: bool, pool: *std.Thread.Pool) !void {
        const current_track = self.getCurrentIndexedTrack();

        var iterator = self.manage_loaded_tracks.iterator();

        while (iterator.next()) |entry| {
            const track = entry.value_ptr.*;

            if (track.quality == quality) {
                continue;
            }

            if (current_track != null and current_track.?.track.id == track.id) {
                if (!perform_hot_swap) {
                    return;
                }
                const current_position = track.getCurrentPlaybackTime();
                track.close();
                track.quality = quality;
                try track.open(pool);
                track.seekWhenReady(current_position, true);
            } else {
                track.close();
                track.quality = quality;
            }
        }
    }
};

pub const LoopMode = enum(u8) {
    none,
    one,
    all,
};

pub const MelodinkTrackRequest = struct {
    id: u64,
    server_url: []const u8,
    downloaded_path: ?[]const u8 = null,
    original_audio_hash: ?[]const u8 = null,
    cache_path: ?[]const u8 = null,
};

pub const Player = struct {
    const Self = @This();

    internal_process_thread: ?Thread = null,

    tracks_mutex: Thread.Mutex = Thread.Mutex{},
    ma_device_mutex: Thread.Mutex = Thread.Mutex{},

    target_quality: TrackQuality,
    current_quality: TrackQuality,

    track_manager: *TrackManager,

    paused: bool = true,
    audio_volume: f64 = 1.0,
    current_virtual_index: u64 = 0,

    loop_mode: LoopMode = .none,

    ma_context: *c.ma_context = undefined,
    ma_device: *c.ma_device = undefined,
    ma_device_config: c.ma_device_config,
    has_init_ma_device: bool = false,

    equalizer: *Equalizer = undefined,

    allocator: std.mem.Allocator,

    send_event_audio_changed: ?c.IntCallback = null,
    send_event_update_state: ?c.IntCallback = null,

    last_sendend_event_update_state: ?TrackStatus = null,

    pool_threads: *std.Thread.Pool = undefined,

    fn sendEventAudioChanged(self: *Self, value: u64) void {
        if (self.send_event_audio_changed == null) {
            return;
        }
        self.send_event_audio_changed.?.?(@intCast(value));
    }

    fn sendEventUpdateState(self: *Self, value: TrackStatus, force: bool) void {
        if (self.send_event_update_state == null) {
            return;
        }
        if (!force and self.last_sendend_event_update_state != null and self.last_sendend_event_update_state.? == value) {
            return;
        }
        self.send_event_update_state.?.?(@intFromEnum(value));
        self.last_sendend_event_update_state = value;
    }

    pub fn new(allocator: std.mem.Allocator) !Self {
        const track_manager = try allocator.create(TrackManager);
        errdefer allocator.destroy(track_manager);

        track_manager.* = TrackManager.init(allocator);

        const pool = try allocator.create(std.Thread.Pool);
        errdefer allocator.destroy(pool);

        try pool.init(std.Thread.Pool.Options{ .allocator = allocator, .n_jobs = 8 });
        errdefer pool.deinit();

        const ma_context = try allocator.create(c.ma_context);
        errdefer allocator.destroy(ma_context);

        var context_config = c.ma_context_config_init();

        context_config.coreaudio.noAudioSessionActivate = c.MA_FALSE;
        context_config.coreaudio.noAudioSessionDeactivate = c.MA_FALSE;
        context_config.coreaudio.sessionCategory = c.ma_ios_session_category_playback;

        if (c.ma_context_init(null, 0, &context_config, ma_context) != c.MA_SUCCESS) {
            return error.CantInitMiniaudioContext;
        }

        const equalizer = try allocator.create(Equalizer);
        errdefer allocator.destroy(equalizer);

        equalizer.* = Equalizer{
            .allocator = allocator,
        };

        return .{
            .allocator = allocator,

            .track_manager = track_manager,

            .target_quality = TrackQuality.lossless,
            .current_quality = TrackQuality.lossless,

            .ma_context = ma_context,
            .ma_device = try allocator.create(c.ma_device),
            .ma_device_config = c.ma_device_config_init(c.ma_device_type_playback),

            .equalizer = equalizer,

            .pool_threads = pool,
        };
    }

    pub fn startInternalThread(self: *Self) !void {
        if (self.internal_process_thread != null) {
            return;
        }
        self.internal_process_thread = try Thread.spawn(.{}, Self.internalThreadTicker, .{self});
    }

    fn internalThreadTicker(self: *Self) void {
        while (true) {
            self.process() catch |err| {
                std.log.err("Error in the internal processing thread {}", .{err});
            };
            std.time.sleep(std.time.ns_per_ms);
        }
    }

    pub fn stopInternalThread(self: *Self) void {
        if (self.internal_process_thread == null) {
            return;
        }
        self.internal_process_thread.?.join();
        self.internal_process_thread = null;
    }

    pub fn free(self: *Self) void {
        self.stopInternalThread();

        if (self.has_init_ma_device) {
            c.ma_device_uninit(self.ma_device);
            self.equalizer.deinit();
            self.has_init_ma_device = false;
        }

        self.track_manager.deinit();

        self.allocator.destroy(self.track_manager);

        self.pool_threads.deinit();

        self.allocator.destroy(self.pool_threads);

        self.allocator.destroy(self.ma_device);

        _ = c.ma_context_uninit(self.ma_context);

        self.allocator.destroy(self.ma_context);

        self.equalizer.free();

        self.allocator.destroy(self.equalizer);
    }

    pub fn play(self: *Self) !void {
        self.paused = false;

        if (!self.has_init_ma_device) {
            return;
        }

        self.ma_device_mutex.lock();
        defer self.ma_device_mutex.unlock();

        if (c.ma_device_start(self.ma_device) != c.MA_SUCCESS) {
            return error.CantStartMiniaudio;
        }
    }

    pub fn pause(self: *Self) !void {
        self.paused = true;

        if (!self.has_init_ma_device) {
            return;
        }

        self.ma_device_mutex.lock();
        defer self.ma_device_mutex.unlock();

        if (c.ma_device_stop(self.ma_device) != c.MA_SUCCESS) {
            return error.CantStopMiniaudio;
        }
    }

    pub fn seek(self: *Self, new_time: f64) !void {
        self.ma_device_mutex.lock();
        defer self.ma_device_mutex.unlock();

        self.tracks_mutex.lock();
        defer self.tracks_mutex.unlock();

        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return;
        }

        if (self.has_init_ma_device and c.ma_device_stop(self.ma_device) != c.MA_SUCCESS) {
            return error.CantStopMiniaudio;
        }

        current_track.?.track.seekWhenReady(new_time, true);

        if (!self.paused and self.has_init_ma_device and c.ma_device_start(self.ma_device) != c.MA_SUCCESS) {
            return error.CantStartMiniaudio;
        }
    }

    pub fn skipToPrevious(self: *Self) void {
        self.previous(true);
    }

    pub fn skipToNext(self: *Self) void {
        self.next(true);
    }

    fn previous(self: *Self, should_reset_old: bool) void {
        self.tracks_mutex.lock();
        defer self.tracks_mutex.unlock();
        defer self.sendEventAudioChanged(self.current_virtual_index);

        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return;
        }

        current_track.?.track.need_reset = should_reset_old;

        const previous_track = current_track.?.previous();

        if (previous_track == null) {
            return;
        }

        self.track_manager.setCurrentIndexedTrack(previous_track);

        self.current_virtual_index -= 1;
    }

    fn next(self: *Self, should_reset_old: bool) void {
        self.tracks_mutex.lock();
        defer self.tracks_mutex.unlock();
        defer self.sendEventAudioChanged(self.current_virtual_index);

        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return;
        }

        const next_track = current_track.?.next() orelse if (self.loop_mode == .all) current_track.?.first() else null;

        if (next_track == null) {
            return;
        }

        current_track.?.track.need_reset = should_reset_old;

        self.track_manager.setCurrentIndexedTrack(next_track);

        if (current_track.?.next() == null and self.loop_mode == .all) {
            self.current_virtual_index = 0;
        } else {
            self.current_virtual_index += 1;
        }
    }

    pub fn setAudios(self: *Self, virtual_index: usize, play_request_index: usize, requests: []const MelodinkTrackRequest, server_auth: []const u8) !void {
        self.tracks_mutex.lock();
        defer self.tracks_mutex.unlock();

        self.current_virtual_index = virtual_index;

        try self.track_manager.loads(play_request_index, requests, self.target_quality, server_auth);
    }

    pub fn setEqualizer(self: *Self, enable: bool, frequencies: []const f64, gains: []const f64) !void {
        self.tracks_mutex.lock();
        defer self.tracks_mutex.unlock();

        try self.equalizer.setSetting(enable, frequencies, gains);

        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return;
        }

        const track = current_track.?.track;

        if (self.has_init_ma_device) {
            self.equalizer.deinit();
        }

        try self.equalizer.init(track.getAudioChannelCount(), track.getAudioSampleRate());
    }

    pub fn process(self: *Self) !void {
        self.tracks_mutex.lock();
        defer self.tracks_mutex.unlock();

        if (self.current_quality != self.target_quality) {
            try self.track_manager.swapTracksQuality(self.target_quality, false, self.pool_threads);
            self.current_quality = self.target_quality;
        }

        self.tracks_mutex.unlock();
        self.tracks_mutex.lock();

        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return;
        }

        current_track.?.track.setLoop(self.loop_mode == .one or (current_track.?.next() != null and current_track.?.next().?.track == current_track.?.track));

        if (current_track.?.track.getStatus() == .idle) {
            try current_track.?.track.open(self.pool_threads);
        }

        if (current_track.?.track.getStatus() != .idle and
            current_track.?.track.getStatus() != .loading and
            !self.isTrackMatchDevice(current_track.?.track))
        {
            try self.initMiniaudio();
        }

        self.sendEventUpdateState(current_track.?.track.getStatus(), false);

        var track_to_load = current_track.?;

        for (0..10) |_| {
            try self.openAndProcessTrack(track_to_load.track);

            if (!Player.isTrackBufferedEnough(track_to_load.track, 4)) {
                return;
            }

            if (track_to_load.index == current_track.?.index) {
                const previous_track = current_track.?.previous();

                if (previous_track != null and
                    !Player.isTrackBufferedEnough(previous_track.?.track, 4))
                {
                    try self.openAndProcessTrack(previous_track.?.track);
                }
            }

            const next_track = track_to_load.next() orelse if (self.loop_mode == .all) track_to_load.first() else null;

            if (next_track == null) {
                return;
            }

            if (!Player.isTrackBufferedEnough(next_track.?.track, 4)) {
                try self.openAndProcessTrack(next_track.?.track);
                return;
            }

            if (!track_to_load.track.haveFinishToLoadEverything()) {
                return;
            }

            track_to_load = next_track.?;
        }
    }

    fn isTrackBufferedEnough(track: *Track, wanted: f64) bool {
        if (track.haveFinishToLoadEverything()) {
            return true;
        }

        const ready_to_read = track.getBufferedPlaybackTime() - track.getCurrentPlaybackTime();

        return ready_to_read > wanted or track.haveReachEnd();
    }

    fn openAndProcessTrack(self: *Self, track: *Track) !void {
        if (track.getStatus() == .idle) {
            try track.open(self.pool_threads);
        }
        try track.process();
    }

    fn initMiniaudio(self: *Self) !void {
        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return;
        }

        self.ma_device_mutex.lock();
        defer self.ma_device_mutex.unlock();

        const track = current_track.?.track;

        self.ma_device_config.playback.format = switch (track.getAudioOutputFormat()) {
            c.AV_SAMPLE_FMT_U8 => c.ma_format_u8,

            c.AV_SAMPLE_FMT_S16 => c.ma_format_s16,

            c.AV_SAMPLE_FMT_S32 => c.ma_format_s32,

            c.AV_SAMPLE_FMT_FLT => c.ma_format_f32,
            else => unreachable,
        };

        self.ma_device_config.playback.channels = @intCast(track.getAudioChannelCount());
        self.ma_device_config.sampleRate = @intCast(track.getAudioSampleRate());

        self.ma_device_config.pUserData = self;

        self.ma_device_config.pulse.pStreamNamePlayback = "Melodink Player";

        self.ma_device_config.dataCallback = &Self.playAudio;

        self.ma_device_config.notificationCallback = &Self.notificationAudio;

        if (self.has_init_ma_device) {
            c.ma_device_uninit(self.ma_device);
            self.equalizer.deinit();
            self.has_init_ma_device = false;
        }

        try self.equalizer.init(track.getAudioChannelCount(), track.getAudioSampleRate());

        if (c.ma_device_init(self.ma_context, &self.ma_device_config, self.ma_device) !=
            c.MA_SUCCESS)
        {
            return error.CantInitMiniaudio;
        }

        self.has_init_ma_device = true;

        if (!self.paused) {
            self.tracks_mutex.unlock();
            if (c.ma_device_start(self.ma_device) != c.MA_SUCCESS) {
                return error.CantStartMiniaudio;
            }
            self.tracks_mutex.lock();
        }

        _ = c.ma_device_set_master_volume(self.ma_device, @floatCast(self.audio_volume));
    }

    fn isTrackMatchDevice(self: *Self, track: *Track) bool {
        if (track.getStatus() == .idle) {
            return false;
        }

        if (switch (track.getAudioOutputFormat()) {
            c.AV_SAMPLE_FMT_U8 => self.ma_device.playback.format != c.ma_format_u8,

            c.AV_SAMPLE_FMT_S16 => self.ma_device.playback.format != c.ma_format_s16,

            c.AV_SAMPLE_FMT_S32 => self.ma_device.playback.format != c.ma_format_s32,

            c.AV_SAMPLE_FMT_FLT => self.ma_device.playback.format != c.ma_format_f32,
            else => true,
        }) {
            return false;
        }

        if (self.ma_device.playback.channels != track.getAudioChannelCount()) {
            return false;
        }

        return self.ma_device.sampleRate == track.getAudioSampleRate();
    }

    fn playAudio(pDevice: ?*anyopaque, output: ?*anyopaque, _: ?*const anyopaque, frame_count: c.ma_uint32) callconv(.c) void {
        const ma_device: *c.ma_device = @ptrCast(@alignCast(pDevice));

        const self: *Self = @ptrCast(@alignCast(ma_device.*.pUserData));

        if ((frame_count < 0)) {
            return;
        }

        readAudio(self, output, @intCast(frame_count));

        if (self.equalizer.enable) {
            switch (self.ma_device.playback.format) {
                c.ma_format_f32 => self.useEqualizer(@as([*]f32, @ptrCast(@alignCast(output))), frame_count),
                c.ma_format_s16 => self.useEqualizer(@as([*]i16, @ptrCast(@alignCast(output))), frame_count),
                c.ma_format_s24 => self.useEqualizer(@as([*]i24, @ptrCast(@alignCast(output))), frame_count),
                c.ma_format_s32 => self.useEqualizer(@as([*]i32, @ptrCast(@alignCast(output))), frame_count),
                c.ma_format_u8 => self.useEqualizer(@as([*]u8, @ptrCast(@alignCast(output))), frame_count),
                else => {},
            }
        }
    }

    fn useEqualizer(self: *Self, out: anytype, frame_count: c.ma_uint32) void {
        for (0..self.ma_device.playback.channels) |ch| {
            for (0..frame_count) |i| {
                out[i * self.ma_device.playback.channels + ch] = self.equalizer.process(out[i * self.ma_device.playback.channels + ch], ch);
            }
        }
    }

    fn readAudio(self: *Self, output: ?*anyopaque, frame_count: u64) void {
        if ((frame_count < 0)) {
            return;
        }

        var remaining_frame: u64 = undefined;

        self.track_manager.current_track_mutex.lock();

        const opt_current_track = self.*.track_manager.getCurrentIndexedTrack();

        if (opt_current_track == null) {
            self.track_manager.current_track_mutex.unlock();
            return;
        }

        const current_track = opt_current_track.?;

        if (!self.isTrackMatchDevice(current_track.track)) {
            self.track_manager.current_track_mutex.unlock();
            return;
        }

        const frame_read, const haveLoopOnItself = current_track.track.getAudioFrame(@ptrCast(@alignCast(@constCast(&output))), @intCast(frame_count)) catch |err| {
            std.log.warn("{}", .{err});
            self.track_manager.current_track_mutex.unlock();
            return;
        };

        const next_track = current_track.next() orelse if (self.loop_mode == .all) current_track.first() else null;

        if ((next_track != null and next_track.?.track == current_track.track) and haveLoopOnItself) {
            self.track_manager.current_track_mutex.unlock();
            self.next(false);
            return;
        }

        if (haveLoopOnItself) {
            self.sendEventUpdateState(current_track.track.getStatus(), true);
        }

        if (frame_read < 0 or self.loop_mode == .one) {
            self.track_manager.current_track_mutex.unlock();
            return;
        }

        remaining_frame = frame_count - frame_read;

        if (remaining_frame == 0) {
            self.track_manager.current_track_mutex.unlock();
            return;
        }

        if (!current_track.track.haveReachEnd()) {
            self.track_manager.current_track_mutex.unlock();
            return;
        }

        if (next_track == null) {
            self.track_manager.current_track_mutex.unlock();
            return;
        }

        self.track_manager.current_track_mutex.unlock();

        self.next(true);

        if (self.isTrackMatchDevice(self.track_manager.getCurrentIndexedTrack().?.track)) {
            self.readAudio(output, remaining_frame);
        }
    }

    fn notificationAudio(pNotification: ?*const anyopaque) callconv(.c) void {
        const ma_device_notification: *const c.ma_device_notification = @ptrCast(@alignCast(pNotification));

        if (ma_device_notification.type != c.ma_device_notification_type_interruption_began) {
            return;
        }

        const self: *Self = @ptrCast(@alignCast(ma_device_notification.*.pDevice.*.pUserData));

        self.pause() catch |err| {
            std.log.warn("Unable to pause : {}", .{err});
            return;
        };

        self.track_manager.current_track_mutex.lock();
        defer self.track_manager.current_track_mutex.unlock();

        const opt_current_track = self.*.track_manager.getCurrentIndexedTrack();

        if (opt_current_track == null) {
            return;
        }

        const current_track = opt_current_track.?;

        self.sendEventUpdateState(current_track.track.getStatus(), true);
    }

    pub fn getIsPlaying(self: *Self) bool {
        if (self.getCurrentState() == .completed) {
            return false;
        }
        return !self.paused;
    }

    pub fn setLoopMode(self: *Self, mode: LoopMode) void {
        self.loop_mode = mode;
    }

    pub fn getLoopMode(self: *Self) LoopMode {
        return self.loop_mode;
    }

    pub fn setQuality(self: *Self, quality: TrackQuality) !void {
        self.target_quality = quality;
    }

    pub fn getCurrentVirtualTrack(self: *Self) u64 {
        return self.current_virtual_index;
    }

    pub fn getCurrentPosition(self: *Self) f64 {
        self.track_manager.current_track_mutex.lock();
        defer self.track_manager.current_track_mutex.unlock();

        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return 0;
        }

        return current_track.?.track.getCurrentPlaybackTime();
    }

    pub fn getBufferedPosition(self: *Self) f64 {
        self.track_manager.current_track_mutex.lock();
        defer self.track_manager.current_track_mutex.unlock();

        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return 0;
        }

        return current_track.?.track.getBufferedPlaybackTime();
    }

    pub fn getCurrentState(self: *Self) TrackStatus {
        self.track_manager.current_track_mutex.lock();
        defer self.track_manager.current_track_mutex.unlock();

        const current_track = self.track_manager.getCurrentIndexedTrack();

        if (current_track == null) {
            return .idle;
        }

        return current_track.?.track.getStatus();
    }

    pub fn setVolume(self: *Self, volume: f64) void {
        var clamped_volume = volume;

        if (volume < 0.0) {
            clamped_volume = 0.0;
        } else if (volume > 1.0) {
            clamped_volume = 1.0;
        }

        self.ma_device_mutex.lock();
        defer self.ma_device_mutex.unlock();

        self.audio_volume = clamped_volume;
        _ = c.ma_device_set_master_volume(self.ma_device, @floatCast(self.audio_volume));
    }

    pub fn getVolume(self: *Self) f64 {
        return self.audio_volume;
    }
};

const t = std.testing;

test "verify setAudios" {
    var player = try Player.new(t.allocator);
    defer player.free();

    const server_url = "https://melodink.com";

    const track_manager = player.track_manager;

    try t.expectEqual(null, track_manager.getCurrentIndexedTrack());

    ////! Load a single track;

    try player.setAudios(0, 0, &[_]MelodinkTrackRequest{
        .{
            .id = 1,
            .server_url = server_url,
        },
    }, "");

    const track1Ref = track_manager.manage_loaded_tracks.get(1);

    try t.expectEqual(1, track_manager.manage_loaded_tracks.count());
    try t.expectEqual(1, track1Ref.?.id);
    try t.expectEqual(track1Ref, track_manager.manage_tracks_order.items[0].track);

    try t.expectEqual(0, player.getCurrentVirtualTrack());
    try t.expectEqual(track1Ref, track_manager.getCurrentIndexedTrack().?.track);

    ////! Load an extra track after;

    try player.setAudios(0, 0, &[_]MelodinkTrackRequest{
        .{
            .id = 1,
            .server_url = server_url,
        },
        .{
            .id = 2,
            .server_url = server_url,
        },
    }, "");

    const track2Ref = track_manager.manage_loaded_tracks.get(2);

    try t.expectEqual(2, track_manager.manage_loaded_tracks.count());

    // Keep the same track ref
    try t.expectEqual(track1Ref, track_manager.manage_loaded_tracks.get(1));

    try t.expectEqual(1, track1Ref.?.id);
    try t.expectEqual(track1Ref, track_manager.manage_tracks_order.items[0].track);

    try t.expectEqual(2, track2Ref.?.id);
    try t.expectEqual(track2Ref, track_manager.manage_tracks_order.items[1].track);

    try t.expectEqual(0, player.getCurrentVirtualTrack());
    try t.expectEqual(track1Ref, track_manager.getCurrentIndexedTrack().?.track);

    ////! Change current track;

    try player.setAudios(1, 1, &[_]MelodinkTrackRequest{
        .{
            .id = 1,
            .server_url = server_url,
        },
        .{
            .id = 2,
            .server_url = server_url,
        },
    }, "");

    try t.expectEqual(2, track_manager.manage_loaded_tracks.count());

    // Keep the same track ref
    try t.expectEqual(track1Ref, track_manager.manage_loaded_tracks.get(1));
    try t.expectEqual(track2Ref, track_manager.manage_loaded_tracks.get(2));

    try t.expectEqual(1, track1Ref.?.id);
    try t.expectEqual(track1Ref, track_manager.manage_tracks_order.items[0].track);

    try t.expectEqual(2, track2Ref.?.id);
    try t.expectEqual(track2Ref, track_manager.manage_tracks_order.items[1].track);

    try t.expectEqual(1, player.getCurrentVirtualTrack());
    try t.expectEqual(track2Ref, track_manager.getCurrentIndexedTrack().?.track);

    ////! Change every tracks at once;

    try player.setAudios(88, 2, &[_]MelodinkTrackRequest{
        .{
            .id = 86,
            .server_url = server_url,
        },
        .{
            .id = 32,
            .server_url = server_url,
        },
        .{
            .id = 42,
            .server_url = server_url,
        },
        .{
            .id = 8,
            .server_url = server_url,
        },
    }, "");

    const track86Ref = track_manager.manage_loaded_tracks.get(86);
    const track32Ref = track_manager.manage_loaded_tracks.get(32);
    const track42Ref = track_manager.manage_loaded_tracks.get(42);
    const track8Ref = track_manager.manage_loaded_tracks.get(8);

    try t.expectEqual(4, track_manager.manage_loaded_tracks.count());

    try t.expectEqual(86, track86Ref.?.id);
    try t.expectEqual(track86Ref, track_manager.manage_tracks_order.items[0].track);

    try t.expectEqual(32, track32Ref.?.id);
    try t.expectEqual(track32Ref, track_manager.manage_tracks_order.items[1].track);

    try t.expectEqual(42, track42Ref.?.id);
    try t.expectEqual(track42Ref, track_manager.manage_tracks_order.items[2].track);

    try t.expectEqual(8, track8Ref.?.id);
    try t.expectEqual(track8Ref, track_manager.manage_tracks_order.items[3].track);

    try t.expectEqual(88, player.getCurrentVirtualTrack());
    try t.expectEqual(track42Ref, track_manager.getCurrentIndexedTrack().?.track);

    ////! Clean the player;

    try player.setAudios(0, 0, &[_]MelodinkTrackRequest{}, "");

    try t.expectEqual(0, track_manager.manage_loaded_tracks.count());

    try t.expectEqual(0, player.getCurrentVirtualTrack());
    try t.expectEqual(null, track_manager.getCurrentIndexedTrack());
}
