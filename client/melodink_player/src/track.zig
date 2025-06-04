const std = @import("std");

const c = @import("c.zig");

const Fifo = @import("fifo.zig");

const CacheAVIO = @import("cache.zig");
const HttpAVIO = @import("http.zig");

const ENABLE_CACHE = true;
const ENABLE_TRACK_OPEN_INFO = false;

pub const TrackStatus = enum(u8) {
    /// There hasn't been any resource loaded yet.
    idle,

    /// Resource is being loaded.
    loading,

    /// Resource is being buffered.
    buffering,

    /// Resource is buffered enough and available for playback.
    ready,

    /// The end of resource was reached.
    completed,
};

pub const TrackQuality = enum(u8) {
    low,
    medium,
    high,
    lossless,
};

const TrackInfo = struct {
    stream_index: usize,
};

const AVPacketFifo = std.fifo.LinearFifo(?*c.AVPacket, .Dynamic);

pub const Track = struct {
    const Self = @This();

    id: u64,
    quality: TrackQuality,

    status: TrackStatus = .idle,

    server_url: []const u8,
    downloaded_path: ?[]const u8,

    server_auth: []const u8,

    original_audio_hash: ?[]const u8,
    http_avio: *HttpAVIO,

    cache_path: ?[]const u8,
    cache_avio: *CacheAVIO,

    open_close_mutex: std.Thread.Mutex = std.Thread.Mutex{},

    allocator: std.mem.Allocator,

    audio_fifo: Fifo = Fifo{},
    cached_packet_fifo: AVPacketFifo,
    last_av_read_frame_response: c_int = 0,

    av_format_ctx: ?*c.AVFormatContext = null,
    av_audio_codec_ctx: ?*c.AVCodecContext = null,
    swr_audio_resampler: ?*c.SwrContext = null,
    audio_stream_index: usize = 0,
    audio_format: c.AVSampleFormat = c.AV_SAMPLE_FMT_NONE,

    audio_frames_consumed: u64 = 0,
    audio_frames_consumed_max: u64 = 0,
    audio_time: f64 = 0,

    audio_sample_size: u8 = 0,
    audio_sample_rate: u64 = 0,
    audio_channel_count: u64 = 0,
    audio_time_base: c.AVRational = undefined,

    av_audio_frame: ?*c.AVFrame = null,
    resampled_audio_frame: ?*c.AVFrame = null,

    has_reach_end: bool = false,

    fast_forward_until_time: ?f64 = null,

    infinite_loop: bool = false,

    need_reset: bool = false,

    debug_test_alloc: (if (@import("builtin").mode == .Debug) *u8 else void) = undefined,

    open_thread: bool = false,
    queue_seek: ?QueueSeek = null,

    const FrameData = extern struct {
        pkt_pos: i64,
        pkt_size: usize,
    };

    pub fn new(allocator: std.mem.Allocator, id: u64, quality: TrackQuality, server_url: []const u8, downloaded_path: ?[]const u8, original_audio_hash: ?[]const u8, cache_path: ?[]const u8, server_auth: []const u8, protected_opened_cache_paths: *CacheAVIO.ProtectedOpenedPathsList) !Self {
        const internal_server_url = try allocator.alloc(u8, server_url.len);
        errdefer allocator.free(internal_server_url);

        std.mem.copyBackwards(u8, internal_server_url, server_url);

        const internal_server_auth = try allocator.alloc(u8, server_auth.len);
        errdefer allocator.free(internal_server_auth);

        std.mem.copyBackwards(u8, internal_server_auth, server_auth);

        var internal_downloaded_path: ?[]u8 = null;

        if (downloaded_path != null) {
            internal_downloaded_path = try allocator.alloc(u8, downloaded_path.?.len);
            std.mem.copyBackwards(u8, internal_downloaded_path.?, downloaded_path.?);
        }
        errdefer if (downloaded_path != null) allocator.free(internal_downloaded_path.?);

        var internal_original_audio_hash: ?[]u8 = null;

        if (original_audio_hash != null) {
            internal_original_audio_hash = try allocator.alloc(u8, original_audio_hash.?.len);
            std.mem.copyBackwards(u8, internal_original_audio_hash.?, original_audio_hash.?);
        }
        errdefer if (original_audio_hash != null) allocator.free(internal_original_audio_hash.?);

        var internal_cache_path: ?[]u8 = null;

        if (cache_path != null) {
            internal_cache_path = try allocator.alloc(u8, cache_path.?.len);
            std.mem.copyBackwards(u8, internal_cache_path.?, cache_path.?);
        }
        errdefer if (cache_path != null) allocator.free(internal_cache_path.?);

        const http_avio = try allocator.create(HttpAVIO);

        http_avio.* = .{
            .allocator = allocator,
        };

        const cache_avio = try allocator.create(CacheAVIO);

        cache_avio.* = .{
            .allocator = allocator,
            .index_map = std.ArrayList(u8).init(allocator),
            .protected_opened_cache_paths = protected_opened_cache_paths,
        };

        return .{
            .allocator = allocator,

            .id = id,
            .quality = quality,
            .server_url = internal_server_url,
            .downloaded_path = internal_downloaded_path,

            .original_audio_hash = internal_original_audio_hash,
            .cache_path = internal_cache_path,

            .server_auth = internal_server_auth,

            .http_avio = http_avio,

            .cache_avio = cache_avio,
            .cached_packet_fifo = AVPacketFifo.init(allocator),
        };
    }

    pub fn free(self: *Self) void {
        self.close();

        self.cached_packet_fifo.deinit();

        self.allocator.free(self.server_url);
        self.allocator.free(self.server_auth);

        if (self.downloaded_path != null) {
            self.allocator.free(self.downloaded_path.?);
        }

        self.cache_avio.index_map.deinit();

        if (self.original_audio_hash != null) {
            self.allocator.free(self.original_audio_hash.?);
        }

        if (self.cache_path != null) {
            self.allocator.free(self.cache_path.?);
        }

        self.allocator.destroy(self.cache_avio);
        self.allocator.destroy(self.http_avio);
    }

    pub fn open(self: *Self, pool: *std.Thread.Pool) !void {
        if (self.open_thread) {
            return;
        }

        if (self.status != TrackStatus.idle) {
            return;
        }

        self.open_thread = true;
        defer self.open_thread = false;
        try pool.spawn(openThreadHandler, .{self});
    }

    fn openThreadHandler(self: *Self) void {
        self.openAndWait() catch |err| {
            std.log.warn("Failed to open track {}", .{err});
        };
    }

    pub fn openAndWait(self: *Self) !void {
        self.open_close_mutex.lock();
        defer self.open_close_mutex.unlock();

        defer self.open_thread = false;
        if (self.status != TrackStatus.idle) {
            return;
        }
        self.status = TrackStatus.loading;
        errdefer self.status = TrackStatus.idle;
        // OpenFile

        if (@import("builtin").mode == .Debug) {
            self.debug_test_alloc = try self.allocator.create(u8);
        }
        errdefer if (@import("builtin").mode == .Debug) self.allocator.destroy(self.debug_test_alloc);

        var open_options: ?*c.AVDictionary = null;

        const headers = try std.fmt.allocPrintZ(self.allocator, "Cookie: {s}\r\nUser-Agent: Melodink-Player\r\nMelodink-Signature: {s}\r\n", .{ self.server_auth, if (self.original_audio_hash == null) "" else self.original_audio_hash.? });
        defer self.allocator.free(headers);

        _ = c.av_dict_set(&open_options, "headers", headers.ptr, 0);

        _ = c.av_dict_set(&open_options, "reconnect", "1", 0);

        _ = c.av_dict_set(&open_options, "reconnect_on_network_error", "1", 0);

        _ = c.av_dict_set(&open_options, "reconnect_streamed", "1", 0);

        _ = c.av_dict_set(&open_options, "reconnect_max_retries", "3", 0);

        _ = c.av_dict_set(&open_options, "rw_timeout", "45000000", 0);

        self.av_format_ctx = c.avformat_alloc_context() orelse {
            std.log.err("Could not allocate AVFormatContext", .{});
            return error.CouldNotAllocateAVFormatContext;
        };
        errdefer c.avformat_free_context(self.av_format_ctx);

        var response: c_int = undefined;

        if (self.downloaded_path == null) {
            var url: [:0]u8 = undefined;
            if (self.quality == .lossless) {
                url = try std.fmt.allocPrintZ(self.allocator, "{s}track/{}/audio", .{ self.server_url, self.id });
            } else {
                url = try std.fmt.allocPrintZ(self.allocator, "{s}track/{}/audio/{s}/transcode", .{ self.server_url, self.id, switch (self.quality) {
                    .low => "low",
                    .medium => "medium",
                    .high => "high",
                    .lossless => unreachable,
                } });
            }

            defer self.allocator.free(url);

            std.log.debug("open url: {s}", .{url});

            try self.http_avio.init(url, &open_options);

            if (ENABLE_CACHE and self.original_audio_hash != null and self.cache_path != null) {
                const cache_key = try std.fmt.allocPrint(self.allocator, "{}-{}-{s}", .{ self.id, self.quality, self.original_audio_hash.? });
                defer self.allocator.free(cache_key);

                try self.cache_avio.init(self.cache_path.?, cache_key, self.http_avio.avio_ctx);

                self.av_format_ctx.?.pb = self.cache_avio.avio_ctx;
                self.av_format_ctx.?.flags |= c.AVFMT_FLAG_CUSTOM_IO;

                response = c.avformat_open_input(&self.av_format_ctx, null, null, null);
            } else {
                self.av_format_ctx.?.pb = self.http_avio.avio_ctx;
                self.av_format_ctx.?.flags |= c.AVFMT_FLAG_CUSTOM_IO;

                response = c.avformat_open_input(&self.av_format_ctx, null, null, null);
            }
        } else {
            const path = try std.fmt.allocPrintZ(self.allocator, "{s}", .{self.downloaded_path.?});
            defer self.allocator.free(path);

            std.log.debug("open file: {s}", .{path});

            response = c.avformat_open_input(&self.av_format_ctx, path.ptr, null, &open_options);
        }

        errdefer if (self.downloaded_path == null and self.original_audio_hash != null and self.cache_path != null) {
            self.cache_avio.deinit();
        };
        errdefer self.http_avio.deinit();

        if (response < 0) {
            std.log.err("avformat_open_input response: {s}", .{self.getAVError(response)});
        }
        if (response != 0) {
            std.log.err("Couldn't open file: most likely format isn't supported", .{});
            return error.CouldNotOpenFile;
        }
        errdefer c.avformat_close_input(&self.av_format_ctx);

        response = c.avformat_find_stream_info(self.av_format_ctx, null);
        if (response < 0) {
            std.log.err("Couldn't find stream info", .{});
            return error.CouldNotFindStreamInfo;
        }

        self.audio_stream_index =
            @intCast(c.av_find_best_stream(self.av_format_ctx, c.AVMEDIA_TYPE_AUDIO, -1, -1, null, 0));

        if (self.audio_stream_index < 0) {
            switch (self.audio_stream_index) {
                c.AVERROR_STREAM_NOT_FOUND => {
                    std.log.err("Unable to find audio stream", .{});
                    return error.CouldNotFindStream;
                },
                c.AVERROR_DECODER_NOT_FOUND => {
                    std.log.err("Couldn't find decoder for any of the audio streams", .{});
                    return error.CouldNotFindDecoder;
                },
                else => {
                    std.log.err("Unknown error occured when trying to find audio stream", .{});
                    return error.Unknown;
                },
            }
        }

        const av_audio_codec_params =
            self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar;

        const av_audio_codec = c.avcodec_find_decoder(
            self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.codec_id,
        );

        // Set up a codec context for the decoder
        self.av_audio_codec_ctx = c.avcodec_alloc_context3(av_audio_codec) orelse {
            std.log.err("Couldn't create AVCodecContext", .{});
            return error.CouldNotAllocateAVCodecContext;
        };
        errdefer c.avcodec_free_context(&self.av_audio_codec_ctx);

        response = c.avcodec_parameters_to_context(self.av_audio_codec_ctx, av_audio_codec_params);
        if (response < 0) {
            std.log.err("Couldn't send parameters to AVCodecContext", .{});
            return error.CouldNotSendParameterToAVCodecContext;
        }

        var codec_options: ?*c.AVDictionary = null;

        _ = c.av_dict_set(&codec_options, "flags", "+copy_opaque", c.AV_DICT_MULTIKEY);

        response = c.avcodec_open2(self.av_audio_codec_ctx, av_audio_codec, &codec_options);
        if (response != 0) {
            std.log.err("Couldn't initialise AVCodecContext", .{});
            return error.CouldNotInitialiseAVCodecContext;
        }

        self.audio_format, self.audio_sample_size = switch (self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.format) {
            c.AV_SAMPLE_FMT_U8, c.AV_SAMPLE_FMT_U8P => .{ c.AV_SAMPLE_FMT_U8, 1 },
            c.AV_SAMPLE_FMT_S16, c.AV_SAMPLE_FMT_S16P => .{
                c.AV_SAMPLE_FMT_S16,
                2,
            },
            c.AV_SAMPLE_FMT_S32, c.AV_SAMPLE_FMT_S32P => .{
                c.AV_SAMPLE_FMT_S32,
                4,
            },
            c.AV_SAMPLE_FMT_FLT, c.AV_SAMPLE_FMT_FLTP => .{
                c.AV_SAMPLE_FMT_FLT,
                4,
            },
            else => .{
                c.AV_SAMPLE_FMT_FLT,
                4,
            },
        };

        response = c.swr_alloc_set_opts2(&self.swr_audio_resampler, &av_audio_codec_params.*.ch_layout, self.audio_format, av_audio_codec_params.*.sample_rate, &av_audio_codec_params.*.ch_layout, av_audio_codec_params.*.format, av_audio_codec_params.*.sample_rate, 0, null);
        if (response != 0) {
            std.log.err("Couldn't allocate SwrContext", .{});
            return error.CouldNotAllocateSwrContext;
        }
        errdefer c.swr_free(&self.swr_audio_resampler);

        // Should be set when decoding
        self.av_audio_codec_ctx.?.pkt_timebase =
            self.av_format_ctx.?.streams[self.audio_stream_index].*.time_base;

        self.audio_time_base = self.av_format_ctx.?.streams[self.audio_stream_index].*.time_base;
        self.audio_channel_count = @intCast(av_audio_codec_params.*.ch_layout.nb_channels);
        self.audio_sample_rate = @intCast(av_audio_codec_params.*.sample_rate);

        self.audio_frames_consumed = 0;
        self.audio_time = 0;
        self.audio_frames_consumed_max = 0;

        try self.audio_fifo.init(self.audio_format, self.audio_channel_count, self.audio_sample_rate * 10);
        errdefer self.audio_fifo.free();

        self.av_audio_frame = c.av_frame_alloc() orelse {
            std.log.err("Couldn't allocate resampled AVFrame", .{});
            return error.CouldNotAllocateResampledAVFrame;
        };
        errdefer c.av_frame_free(&self.av_audio_frame);

        // Used to store converted "av_audio_frame"
        self.resampled_audio_frame = c.av_frame_alloc() orelse {
            std.log.err("Couldn't allocate resampled AVFrame", .{});
            return error.CouldNotAllocateResampledAVFrame;
        };
        errdefer c.av_frame_free(&self.resampled_audio_frame);

        self.status = TrackStatus.buffering;

        if (ENABLE_TRACK_OPEN_INFO) {
            self.logInfo();
        }
    }

    pub fn logInfo(self: *Self) void {
        if (self.getStatus() == .idle or
            self.getStatus() == .loading)
        {
            return;
        }

        const audio_stream = self.av_format_ctx.?.streams[self.audio_stream_index];
        const frame_size =
            self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.frame_size;
        const sample_rate =
            self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.sample_rate;
        const channels = self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.ch_layout.nb_channels;
        const time_base_num = audio_stream.*.time_base.num;
        const time_base_den = audio_stream.*.time_base.den;
        const pkt_time_base_num = self.av_audio_codec_ctx.?.pkt_timebase.num;
        const pkt_time_base_den = self.av_audio_codec_ctx.?.pkt_timebase.den;
        const ctx_sample_rate = self.av_audio_codec_ctx.?.sample_rate;

        const duration_origin = self.av_format_ctx.?.duration;
        const duration = @divTrunc(duration_origin, c.AV_TIME_BASE);
        const duration_h = @divTrunc(duration, 3600);
        const duration_min = @divTrunc(@rem(duration, 3600), 60);
        const duration_sec = @rem(duration, 60);

        std.log.info("----------------------", .{});
        std.log.info("Audio info", .{});

        std.log.info("Codec: {s}", .{self.av_audio_codec_ctx.?.codec.*.long_name});
        std.log.info("Frame size: {}", .{frame_size});
        std.log.info("Original format type: {s}", .{c.av_get_sample_fmt_name(self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.format)});
        std.log.info("Output format type: {s}", .{c.av_get_sample_fmt_name(self.audio_format)});
        std.log.info("Duration_origin: {}", .{duration_origin});
        std.log.info("Duration: {}:{}:{} h:min:sec", .{ duration_h, duration_min, duration_sec });
        std.log.info("Sample rate: {}", .{sample_rate});
        std.log.info("Channels: {}", .{channels});
        std.log.info("Time base num: {}", .{time_base_num});
        std.log.info("Time base den: {}", .{time_base_den});
        std.log.info("Packet time base num: {}", .{pkt_time_base_num});
        std.log.info("Packet time base den: {}", .{pkt_time_base_den});
        std.log.info("Ctx sample rate: {}", .{ctx_sample_rate});
        std.log.info("block_align: {}", .{self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.block_align});
        std.log.info("initial_padding: {}", .{self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.initial_padding});
        std.log.info("trailing_padding: {}", .{self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.trailing_padding});
        std.log.info("seek_preroll: {}", .{self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.seek_preroll});
        std.log.info("----------------------", .{});
    }

    pub fn process(self: *Self) !void {
        if (self.getStatus() == .idle or
            self.getStatus() == .loading)
        {
            return;
        }

        if (self.queue_seek != null) {
            try self.seek(self.queue_seek.?.new_time, self.queue_seek.?.reset_fifo);
        }

        if (self.need_reset) {
            defer self.need_reset = false;
            if (self.getCurrentPlaybackTime() != 0) {
                try self.seek(0, true);
            }
        }

        if (self.has_reach_end and self.cached_packet_fifo.count == 0) {
            if (self.infinite_loop) {
                try self.loop();
                return;
            }
            self.status = TrackStatus.completed;
            return;
        }

        // Minimum amount of frames that should be pre-decoded
        const min_audio_queue_size = @max(@divTrunc(self.audio_fifo.capacity(), 2), 1);

        var total_written: usize = 0;

        if (self.audio_fifo.size() > 0) {
            self.status = TrackStatus.ready;
        } else {
            self.status = TrackStatus.buffering;
        }

        // Prevent overflow the packet cache queue

        if (self.last_av_read_frame_response >= 0) {
            var new_av_packet = c.av_packet_alloc() orelse {
                std.log.err("Couldn't allocate resampled AVPacket", .{});
                return error.CouldNotAllocateResampledAVPacket;
            };
            errdefer c.av_packet_free(&new_av_packet);

            // Try reading next packet
            errdefer c.av_packet_unref(new_av_packet);
            self.last_av_read_frame_response = c.av_read_frame(self.av_format_ctx, new_av_packet);
            // std.debug.print("{}\n", .{self.last_av_read_frame_response});

            // Return if error or end of file was encountered

            if (self.last_av_read_frame_response >= 0) {
                try self.cached_packet_fifo.writeItem(new_av_packet);
            } else {
                defer c.av_packet_free(&new_av_packet);
                defer c.av_packet_unref(new_av_packet);
            }
        }

        // Dont overflow the decoded buffer

        if ((self.audio_fifo.size() >= min_audio_queue_size)) {
            return;
        }

        if (self.last_av_read_frame_response < 0 and self.cached_packet_fifo.count == 0) {
            defer self.last_av_read_frame_response = 0;
            self.has_reach_end = true;

            if (self.last_av_read_frame_response == c.AVERROR_EOF and
                self.infinite_loop)
            {
                try self.loop();
                return;
            }

            std.debug.print("Error or end of file happened\n", .{});
            std.debug.print("Exit info: {s}\n", .{self.getAVError(self.last_av_read_frame_response)});

            return;
        }

        var av_packet = self.cached_packet_fifo.readItem() orelse {
            return;
        };
        defer c.av_packet_free(&av_packet);
        defer c.av_packet_unref(av_packet);

        // Read last cached AV Packet

        if (av_packet.?.stream_index == self.audio_stream_index) {
            var fd: *FrameData = undefined;

            av_packet.?.opaque_ref = c.av_buffer_allocz(@sizeOf(FrameData));

            if (av_packet.?.opaque_ref != null) {
                fd = @ptrCast(@alignCast(av_packet.?.opaque_ref.*.data));
                fd.*.pkt_pos = av_packet.?.pos;
                fd.*.pkt_size = @intCast(av_packet.?.size);
            }

            // Send packet to decode
            var response = c.avcodec_send_packet(self.av_audio_codec_ctx, av_packet);
            if (response < 0) {
                if (response != c.AVERROR(c.EAGAIN)) {
                    std.log.warn("Failed to decode packet\n", .{});
                    c.av_packet_unref(av_packet);
                }
            }

            while (true) {
                response = c.avcodec_receive_frame(self.av_audio_codec_ctx, self.av_audio_frame);
                if (response < 0) {
                    if (response != c.AVERROR_EOF and response != c.AVERROR(c.EAGAIN)) {
                        std.log.err("Something went wrong when trying to receive decoded frame", .{});
                        return error.ErrorWhileDecodingFrame;
                    }
                    break;
                }

                const fd2: ?*FrameData = if (self.av_audio_frame.?.opaque_ref != null)
                    @ptrCast(@alignCast(self.av_audio_frame.?.opaque_ref.*.data))
                else
                    null;

                // We don't want to do anything with empty frame
                if (fd2 != null and fd2.?.pkt_size != -1) {
                    if (self.fast_forward_until_time == null or self.calculateAudioPts(self.av_audio_frame.?) >= self.fast_forward_until_time.?) {
                        if (self.fast_forward_until_time != null) {
                            self.audio_time = self.calculateAudioPts(self.av_audio_frame.?);
                            self.audio_frames_consumed = @intFromFloat(self.audio_time * @as(f64, @floatFromInt(self.audio_sample_rate)));
                            self.fast_forward_until_time = null;
                        }

                        // We have to manually copy some frame data
                        self.resampled_audio_frame.?.sample_rate = self.av_audio_frame.?.sample_rate;
                        self.resampled_audio_frame.?.ch_layout = self.av_audio_frame.?.ch_layout;
                        self.resampled_audio_frame.?.format = self.audio_format;

                        defer c.av_frame_unref(self.av_audio_frame);
                        response = c.swr_convert_frame(self.swr_audio_resampler, self.resampled_audio_frame, self.av_audio_frame);
                        if (response != 0) {
                            if (response == c.AVERROR_INPUT_CHANGED and self.av_audio_frame.?.sample_rate == self.getAudioSampleRate() and self.av_audio_frame.?.format == self.getAudioOutputFormat()) {
                                // Insert decoded audio samples without resampling (this may be a problem later but for now this fix the WAV file)
                                const samples_written =
                                    try self.audio_fifo.push(@ptrCast(&self.av_audio_frame.?.data), @intCast(self.av_audio_frame.?.nb_samples));
                                total_written += @intCast(samples_written);
                                continue;
                            }

                            std.log.err("Couldn't resample the frame", .{});
                            return error.CouldNotResampleFrame;
                        }

                        // Insert decoded audio samples
                        const samples_written =
                            try self.audio_fifo.push(@ptrCast(&self.resampled_audio_frame.?.data), @intCast(self.resampled_audio_frame.?.nb_samples));
                        total_written += @intCast(samples_written);

                        // Get remaining audio from previous conversion
                        while (c.swr_get_delay(self.swr_audio_resampler, @max(self.resampled_audio_frame.?.sample_rate, self.av_audio_frame.?.sample_rate)) > 0) {
                            response = c.swr_convert_frame(self.swr_audio_resampler, self.resampled_audio_frame, null);
                            if (response != 0) {
                                std.log.err("Couldn't resample the frame\n", .{});
                                return error.CouldNotResampleFrame;
                            }

                            _ =
                                try self.audio_fifo.push(@ptrCast(&self.resampled_audio_frame.?.data), @intCast(self.resampled_audio_frame.?.nb_samples));
                        }
                    }
                }
            }
        }
    }

    pub fn haveFinishToLoadEverything(self: *Self) bool {
        if (self.status == .completed) {
            return true;
        }

        if (self.last_av_read_frame_response < 0) {
            if (self.last_av_read_frame_response == c.AVERROR_EOF and
                self.infinite_loop)
            {
                return false;
            }

            return self.last_av_read_frame_response == c.AVERROR_EOF;
        }

        return false;
    }

    fn loop(self: *Self) !void {
        if (self.audio_frames_consumed_max == 0) {
            self.audio_frames_consumed_max =
                self.audio_frames_consumed + self.audio_fifo.size();
        }

        try self.seek(0, false);

        self.fast_forward_until_time = null;

        self.has_reach_end = false;
    }

    const QueueSeek = struct {
        new_time: f64,
        reset_fifo: bool,
    };

    pub fn seekWhenReady(self: *Self, new_time: f64, reset_fifo: bool) void {
        self.queue_seek = .{
            .new_time = new_time,
            .reset_fifo = reset_fifo,
        };
    }

    fn seek(self: *Self, new_time: f64, reset_fifo: bool) !void {
        if (self.status == TrackStatus.idle or self.status == TrackStatus.loading) {
            return;
        }

        self.status = TrackStatus.loading;
        defer self.status = TrackStatus.buffering;

        self.queue_seek = null;

        self.has_reach_end = false;

        const current = self.getCurrentPlaybackTime();

        const diff = new_time - current;

        const sample_count: i64 = @intFromFloat(diff * @as(f64, @floatFromInt(self.audio_sample_rate)));

        if (sample_count > 0 and sample_count <= self.audio_fifo.size()) {
            self.audio_fifo.drain(@intCast(sample_count));

            self.audio_frames_consumed += @intCast(sample_count);

            return;
        }

        self.fast_forward_until_time = new_time;

        // Note: Zero some time don't reset, so if we try to set 0, we got a
        // little higher
        const response = c.av_seek_frame(self.av_format_ctx, -1, if (new_time == 0) 1953 else @intFromFloat(@as(f64, @floatFromInt(c.AV_TIME_BASE)) * new_time), c.AVSEEK_FLAG_BACKWARD);

        if (response >= 0) {
            if (reset_fifo) {
                while (true) {
                    var av_packet = self.cached_packet_fifo.readItem() orelse {
                        break;
                    };
                    defer c.av_packet_free(&av_packet);
                    defer c.av_packet_unref(av_packet);
                }

                self.last_av_read_frame_response = 0;

                self.audio_frames_consumed_max = 0;
                self.audio_fifo.clear();
                c.avcodec_flush_buffers(self.av_audio_codec_ctx);

                self.audio_time = new_time;
                self.audio_frames_consumed = @intFromFloat(self.audio_time * @as(f64, @floatFromInt(self.audio_sample_rate)));
            } else {
                self.fast_forward_until_time = null;
            }
        } else {
            self.fast_forward_until_time = null;
            return error.CantSeek;
        }
    }

    pub fn setLoop(self: *Self, enabled: bool) void {
        self.infinite_loop = enabled;
    }

    pub fn getAudioFrame(self: *Self, output: [*c]?*anyopaque, sample_count: u64) !std.meta.Tuple(&.{ u64, bool }) {
        var haveLoopOnItself = false;

        if (output == 0) {
            return error.CantGetAudioFrame;
        }

        // if (*output == 0) {
        // return error.CantGetAudioFrame;
        // }

        if (sample_count < 0) {
            return error.CantGetAudioFrame;
        }

        if (self.fast_forward_until_time != null) {
            return .{ 0, haveLoopOnItself };
        }

        if (self.need_reset) {
            return .{ 0, haveLoopOnItself };
        }

        if (!self.audio_fifo.available()) {
            return .{ 0, haveLoopOnItself };
        }

        var sample_count_without_extra_loop: ?u64 = null;

        if (!self.infinite_loop and self.audio_frames_consumed_max != 0) {
            if (self.audio_frames_consumed + sample_count >= self.audio_frames_consumed_max) {
                sample_count_without_extra_loop = self.audio_frames_consumed_max - self.audio_frames_consumed;

                if (sample_count_without_extra_loop.? > sample_count) {
                    sample_count_without_extra_loop = sample_count;
                }
            }
        }

        const samples_read = try self.audio_fifo.pop(output, sample_count_without_extra_loop orelse sample_count);

        if (sample_count_without_extra_loop != null) {
            self.audio_fifo.clear();
        }

        if (samples_read < 0)
            return .{ samples_read, haveLoopOnItself };

        self.audio_frames_consumed += samples_read;

        if (self.infinite_loop and
            self.audio_frames_consumed_max != 0 and
            self.audio_frames_consumed >= self.audio_frames_consumed_max)
        {
            self.audio_frames_consumed = @mod(self.audio_frames_consumed, self.audio_frames_consumed_max);
            haveLoopOnItself = true;
        }

        self.audio_time = @as(f64, @floatFromInt(self.audio_frames_consumed)) / @as(f64, @floatFromInt(self.audio_sample_rate));

        return .{ samples_read, haveLoopOnItself };
    }

    pub fn close(self: *Self) void {
        self.open_close_mutex.lock();
        defer self.open_close_mutex.unlock();
        if (self.status == TrackStatus.idle) {
            return;
        }

        while (true) {
            var av_packet = self.cached_packet_fifo.readItem() orelse {
                break;
            };
            defer c.av_packet_free(&av_packet);
            defer c.av_packet_unref(av_packet);
        }

        c.av_frame_free(&self.av_audio_frame);
        c.av_frame_free(&self.resampled_audio_frame);

        self.audio_fifo.free();
        c.swr_free(&self.swr_audio_resampler);
        c.avcodec_free_context(&self.av_audio_codec_ctx);
        c.avformat_close_input(&self.av_format_ctx);

        self.cache_avio.deinit();
        self.http_avio.deinit();

        c.avformat_free_context(self.av_format_ctx);

        self.status = TrackStatus.idle;

        if (@import("builtin").mode == .Debug) {
            self.allocator.destroy(self.debug_test_alloc);
        }

        self.audio_frames_consumed = 0;
        self.audio_frames_consumed_max = 0;
        self.audio_time = 0;
    }

    pub fn getAudioOutputFormat(self: *const Self) c.AVSampleFormat {
        return self.audio_format;
    }

    pub fn getAudioOriginalFormat(self: *const Self) c.AVSampleFormat {
        return self.av_format_ctx.?.streams[self.audio_stream_index].*.codecpar.*.format;
    }

    pub fn getAudioSampleSize(self: *const Self) u8 {
        return self.audio_sample_size;
    }

    pub fn getAudioSampleRate(self: *const Self) u64 {
        return self.audio_sample_rate;
    }

    pub fn getAudioChannelCount(self: *const Self) u64 {
        return self.audio_channel_count;
    }

    pub fn getCurrentPlaybackTime(self: *const Self) f64 {
        if (self.fast_forward_until_time != null) {
            return self.fast_forward_until_time.?;
        }
        return self.audio_time;
    }

    pub fn getBufferedPlaybackTime(self: *Self) f64 {
        if (self.status == .idle or self.status == .loading) {
            return 0;
        }

        if (self.fast_forward_until_time != null) {
            return self.fast_forward_until_time.?;
        }

        const samples_read = self.audio_fifo.size();

        var audio_frames_consumed = self.audio_frames_consumed + samples_read;

        if (self.infinite_loop and
            self.audio_frames_consumed_max != 0 and
            audio_frames_consumed >= self.audio_frames_consumed_max)
        {
            audio_frames_consumed = self.audio_frames_consumed_max;
        }

        const buffered_time = @as(f64, @floatFromInt(audio_frames_consumed)) / @as(f64, @floatFromInt(self.audio_sample_rate));

        return buffered_time;
    }

    pub fn getStatus(self: *Self) TrackStatus {
        if (self.status == .completed and self.audio_fifo.size() > 0) {
            return .ready;
        }

        if (self.status == .ready and self.audio_time == 0) {
            return .buffering;
        }
        return self.status;
    }

    pub fn haveReachEnd(self: *Self) bool {
        return self.status == .completed and self.audio_fifo.size() == 0 and !self.need_reset;
    }

    fn calculateAudioPts(self: *Self, frame: *c.AVFrame) f64 {
        return (@as(f64, @floatFromInt(frame.*.best_effort_timestamp)) * @as(f64, @floatFromInt(self.audio_time_base.num))) /
            @as(f64, @floatFromInt(self.audio_time_base.den));
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
};
