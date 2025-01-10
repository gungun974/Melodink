#pragma once

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
}

#include <atomic>
#include <cassert>
#include <mutex>
#include <string>
#include <thread>

#include <cstdio>

#define END_SEQUENCE "MelodinkStreamEndOfFile"
#define END_SEQUENCE_LEN (strlen(END_SEQUENCE))

class StreamAvio {
private:
  int overlap_len = 0;

  static int CustomReadPacket(void *opaque, uint8_t *buf, int buf_size) {
    StreamAvio *streamAvio = reinterpret_cast<StreamAvio *>(opaque);

    if (streamAvio->overlap_len == END_SEQUENCE_LEN) {
      return AVERROR_EOF;
    }

    if (streamAvio->source_avio_ctx == nullptr) {
      return AVERROR_EOF;
    }

    int bytes_read = avio_read(streamAvio->source_avio_ctx, buf,
                               buf_size - END_SEQUENCE_LEN - 1);

    if (bytes_read <= 0) {
      if (bytes_read == AVERROR_EOF) {
        return AVERROR(EIO);
      }
      return bytes_read;
    }

    int local_overlap_len = 0;

    for (int i = 0; i < bytes_read; i++) {
      if (buf[i] == END_SEQUENCE[streamAvio->overlap_len]) {
        streamAvio->overlap_len++;
        local_overlap_len++;
        if (streamAvio->overlap_len == END_SEQUENCE_LEN) {
          return bytes_read - local_overlap_len;
        }
      } else {
        if (streamAvio->overlap_len > i) {
          memmove(buf + streamAvio->overlap_len - local_overlap_len, buf,
                  (buf_size - streamAvio->overlap_len - local_overlap_len) *
                      sizeof(uint8_t));
          memcpy(buf, END_SEQUENCE,
                 (streamAvio->overlap_len - local_overlap_len) *
                     sizeof(uint8_t));
          bytes_read += streamAvio->overlap_len - local_overlap_len;
        }
        streamAvio->overlap_len = 0;
        local_overlap_len = 0;
      }
    }

    return bytes_read - local_overlap_len;
  }

  static int64_t CustomSeek(void *opaque, int64_t offset, int whence) {
    StreamAvio *streamAvio = reinterpret_cast<StreamAvio *>(opaque);

    return avio_seek(streamAvio->source_avio_ctx, offset, whence);
  }

  // av_err2str returns a temporary array. This doesn't work in gcc.
  // This function can be used as a replacement for av_err2str.
  static const char *GetError(int errnum) {
    static char str[AV_ERROR_MAX_STRING_SIZE];
    memset(str, 0, sizeof(str));
    return av_make_error_string(str, AV_ERROR_MAX_STRING_SIZE, errnum);
  }

  bool has_been_open = false;

  int buffer_size = 4096;

public:
  AVIOContext *source_avio_ctx = nullptr;
  AVIOContext *avio_ctx = nullptr;

  StreamAvio() {}

  ~StreamAvio() { free(); }

  int init(const char *filename, AVDictionary **options) {
    if (has_been_open) {
      return -1;
    }

    int response =
        avio_open2(&source_avio_ctx, filename, AVIO_FLAG_READ, NULL, options);
    if (response < 0) {
      fprintf(stderr, "Could not open AVIOContext: %s\n", GetError(response));
      return -1;
    }

    uint8_t *buffer = reinterpret_cast<uint8_t *>(av_malloc(buffer_size));
    if (!buffer) {
      avio_closep(&source_avio_ctx);
      fprintf(stderr, "Could not open custom AVIOContext buffer\n");
      return -1;
    }

    avio_ctx = avio_alloc_context(buffer, buffer_size, 0, this,
                                  &StreamAvio::CustomReadPacket, NULL,
                                  &StreamAvio::CustomSeek);
    if (!avio_ctx) {
      av_freep(&buffer);
      avio_closep(&source_avio_ctx);

      fprintf(stderr, "Could not open custom AVIOContext\n",
              GetError(response));
      return -1;
    }

    has_been_open = true;
    return 0;
  }

  void free() {
    if (!has_been_open) {
      return;
    }

    uint8_t *buffer = avio_ctx->buffer;

    avio_context_free(&avio_ctx);
    avio_closep(&source_avio_ctx);

    av_freep(&buffer);

    has_been_open = false;
  }
};
