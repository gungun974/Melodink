const std = @import("std");

const c = @import("c.zig");

const PlayerMod = @import("player.zig");
const Player = PlayerMod.Player;

var player: ?Player = null;
var gpa: std.heap.DebugAllocator(.{}) = undefined;
var allocator: std.mem.Allocator = undefined;

pub export fn mi_player_init() void {
    if (player != null) {
        return;
    }

    c.av_log_set_level(c.AV_LOG_QUIET);

    gpa = std.heap.DebugAllocator(.{}).init;

    allocator = gpa.allocator();

    player = Player.new(allocator) catch |err| {
        std.log.warn("Failed to init MelodinkPlayer : {}", .{err});
        _ = gpa.deinit();
        return;
    };

    player.?.startInternalThread() catch |err| {
        std.log.warn("Failed to start MelodinkPlayer internal thread : {}", .{err});
        mi_player_free();
        return;
    };
}

pub export fn mi_player_free() void {
    if (player == null) {
        return;
    }

    defer _ = gpa.deinit();

    player.?.free();

    player = null;
}

pub export fn mi_register_event_audio_changed_callback(callback: c.IntCallback) void {
    player.?.send_event_audio_changed = callback;
}

pub export fn mi_register_event_update_state_callback(callback: c.IntCallback) void {
    player.?.send_event_update_state = callback;
}

pub export fn mi_player_play() void {
    player.?.play() catch |err| {
        std.log.warn("Unable to play : {}", .{err});
    };
}

pub export fn mi_player_pause() void {
    player.?.pause() catch |err| {
        std.log.warn("Unable to pause : {}", .{err});
    };
}

pub export fn mi_player_seek(position: f64) void {
    player.?.seek(position) catch |err| {
        std.log.warn("Unable to seek : {}", .{err});
    };
}

pub export fn mi_player_skip_to_previous() void {
    player.?.skipToPrevious();
}

pub export fn mi_player_skip_to_next() void {
    player.?.skipToNext();
}

pub const ExternalMelodinkTrackRequest = extern struct {
    serverURL: [*c]const u8,
    cachePath: [*c]const u8,
    trackId: u64,
    originalAudioHash: [*c]const u8,
    downloadedPath: [*c]const u8,
};

pub export fn mi_player_set_audios(virtual_index: usize, play_request_index: usize, requests: [*c]const ExternalMelodinkTrackRequest, request_count: usize) void {
    loadCMelodinkRequest(virtual_index, play_request_index, requests, request_count) catch |err| {
        std.log.warn("Unable to set audios : {}", .{err});
    };
}

pub fn loadCMelodinkRequest(virtual_index: usize, play_request_index: usize, requests: [*c]const ExternalMelodinkTrackRequest, request_count: usize) !void {
    const melodink_requests = try allocator.alloc(PlayerMod.MelodinkTrackRequest, request_count);
    defer allocator.free(melodink_requests);

    for (0..request_count) |i| {
        const request = requests[i];

        melodink_requests[i] = .{
            .id = @intCast(request.trackId),
            .server_url = request.serverURL[0..std.mem.len(request.serverURL)],
            .downloaded_path = if (request.downloadedPath != null) request.downloadedPath[0..std.mem.len(request.downloadedPath)] else null,
            .original_audio_hash = if (request.originalAudioHash != null) request.originalAudioHash[0..std.mem.len(request.originalAudioHash)] else null,
            .cache_path = if (request.cachePath != null) request.cachePath[0..std.mem.len(request.cachePath)] else null,
        };
    }

    try player.?.setAudios(virtual_index, play_request_index, melodink_requests);
}

pub export fn mi_player_set_loop_mode(loop: u8) void {
    player.?.setLoopMode(@enumFromInt(loop));
}

pub export fn mi_player_set_quality(quality: u8) void {
    player.?.setQuality(@enumFromInt(quality)) catch |err| {
        std.log.warn("Unable to change quality : {}", .{err});
    };
}

pub export fn mi_player_set_auth_token(auth_token: [*c]const u8) void {
    player.?.setAuthToken(auth_token[0..std.mem.len(auth_token)]) catch |err| {
        std.log.warn("Unable to set auth token : {}", .{err});
    };
}

pub export fn mi_player_get_current_playing() bool {
    return player.?.getIsPlaying();
}

pub export fn mi_player_get_current_track_pos() u64 {
    return player.?.getCurrentVirtualTrack();
}

pub export fn mi_player_get_current_position() f64 {
    return player.?.getCurrentPosition();
}

pub export fn mi_player_get_current_buffered_position() f64 {
    return player.?.getBufferedPosition();
}

pub export fn mi_player_get_current_player_state() u8 {
    return @intFromEnum(player.?.getCurrentState());
}

pub export fn mi_player_get_current_loop_mode() u8 {
    return @intFromEnum(player.?.getLoopMode());
}

pub export fn mi_player_set_volume(volume: f64) void {
    player.?.setVolume(volume);
}

pub export fn mi_player_get_volume() f64 {
    return player.?.getVolume();
}

test "tests" {
    _ = @import("player.zig");
}
