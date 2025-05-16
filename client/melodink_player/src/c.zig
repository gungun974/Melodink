pub usingnamespace @cImport({
    @cDefine("MKTAG(a, b, c, d)", " ((a) | ((b) << 8) | ((c) << 16) | ((uint64_t)(d) << 24))");

    @cInclude("libavcodec/avcodec.h");
    @cInclude("libavformat/avformat.h");
    @cInclude("libavutil/audio_fifo.h");
    @cInclude("libavutil/avutil.h");
    @cInclude("libswresample/swresample.h");

    @cInclude("miniaudio.h");
});

pub const IntCallback = ?*const fn (c_int) callconv(.c) void;
