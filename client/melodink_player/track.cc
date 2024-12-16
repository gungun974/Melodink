#pragma once

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>

#include <libavutil/avutil.h>
#include <libswresample/swresample.h>
}

#include <atomic>
#include <cassert>
#include <condition_variable>
#include <mutex>
#include <queue>
#include <string>
#include <thread>

#include <cstdio>

#include "fifo.cc"

typedef struct FrameData {
  int64_t pkt_pos;
  int pkt_size;
} FrameData;

class MelodinkTrack {
private:
  bool endsWith(const std::string &str, const std::string &suffix) {
    size_t pos = str.rfind(suffix);
    return pos != std::string::npos && pos == str.size() - suffix.size();
  }

  AVFormatContext *av_format_ctx = nullptr;

  std::string loaded_url = "";
  std::string stored_auth_token = "";
  bool audio_opened = false;
  bool audio_retry = false;

  std::atomic<bool> finished_reading{true};
  std::atomic<bool> keep_loading{true};

  std::atomic<int64_t> max_preload_cache{100 * 1024}; // 100KiB

  std::atomic<bool> infinite_loop{false};

  std::thread decoding_thread;
  std::mutex decoding_mutex;

  std::mutex open_mutex;
  std::mutex seek_mutex;

  int audio_stream_index = -1;
  AVRational audio_time_base;

  AudioFifo audio_fifo;

  const AVCodec *av_audio_codec = nullptr;
  AVCodecContext *av_audio_codec_ctx = nullptr;

  SwrContext *swr_audio_resampler = nullptr;

  AVSampleFormat audio_format;

  size_t audio_frames_consumed = 0;
  size_t audio_frames_consumed_max = -1;
  std::atomic<int64_t> audio_time{0};

  int audio_sample_size = 0;
  int audio_sample_rate = 0;
  int audio_channel_count = 0;

  bool is_transcoding = false;

  int OpenFile(const char *filename, const char *auth_token,
               int64_t streamOffset) {
    int response;

    AVDictionary *options = NULL;

    char headers[1024];
    snprintf(headers, sizeof(headers),
             "Cookie: %s\r\n"
             "User-Agent: Melodink-Player\r\n"
             "X-Melodink-Stream-Offset: %" PRIu64 "\r\n",
             auth_token, streamOffset);

    av_dict_set(&options, "headers", headers, 0);

    av_dict_set(&options, "reconnect", "0", 0);

    av_dict_set(&options, "reconnect_on_network_error", "0", 0);

    av_dict_set(&options, "reconnect_at_eof", "0", 0);

    av_dict_set(&options, "reconnect_streamed", "1", 0);

    av_dict_set(&options, "rw_timeout", "45000000", 0);

    char cleaned_filename[1024];

    strcpy(cleaned_filename, filename);

    char *unique_index_mark = strrchr(cleaned_filename, '?');

    if (unique_index_mark != nullptr) {
      *unique_index_mark = '\0';
    }

    is_transcoding = endsWith(cleaned_filename, "/transcode");

    response =
        avformat_open_input(&av_format_ctx, cleaned_filename, NULL, &options);
    if (response < 0) {
      fprintf(stderr, "avformat_open_input response: %s\n", GetError(response));
    }
    if (response != 0) {
      fprintf(stderr,
              "Couldn't open file: most likely format isn't supported\n");
      return -1;
    }

    response = avformat_find_stream_info(av_format_ctx, nullptr);
    if (response < 0) {
      fprintf(stderr, "Couldn't find stream info\n");
      avformat_close_input(&av_format_ctx);
      avformat_free_context(av_format_ctx);
      return -1;
    }

    return 0;
  }

  void CloseFile() {
    avformat_close_input(&av_format_ctx);
    avformat_free_context(av_format_ctx);
  }

  int InitAudio(bool reopen_fifo) {
    int response;
    int result;

    AVCodecParameters *av_audio_codec_params = nullptr;

    audio_stream_index =
        av_find_best_stream(av_format_ctx, AVMEDIA_TYPE_AUDIO, -1, -1,
                            (const AVCodec **)&av_audio_codec, 0);
    if (audio_stream_index < 0) {
      if (audio_stream_index == AVERROR_STREAM_NOT_FOUND) {
        fprintf(stderr, "Unable to find audio stream\n");
        return -1;
      } else if (audio_stream_index == AVERROR_DECODER_NOT_FOUND) {
        fprintf(stderr, "Couldn't find decoder for any of the audio streams\n");
        return -1;
      } else {
        fprintf(stderr,
                "Unknown error occured when trying to find audio stream\n");
        return -1;
      }
    }

    av_audio_codec_params =
        av_format_ctx->streams[audio_stream_index]->codecpar;

    // Set up a codec context for the decoder
    av_audio_codec_ctx = avcodec_alloc_context3(av_audio_codec);
    if (av_audio_codec_ctx == nullptr) {
      fprintf(stderr, "Couldn't create AVCodecContext\n");
      return -1;
    }

    response = avcodec_parameters_to_context(av_audio_codec_ctx,
                                             av_audio_codec_params);
    if (response < 0) {
      fprintf(stderr, "Couldn't send parameters to AVCodecContext\n");
      return -1;
    }

    AVDictionary *opts = NULL;

    av_dict_set(&opts, "flags", "+copy_opaque", AV_DICT_MULTIKEY);

    response = avcodec_open2(av_audio_codec_ctx, av_audio_codec, &opts);
    if (response != 0) {
      fprintf(stderr, "Couldn't initialise AVCodecContext\n");
      return -1;
    }

    switch ((AVSampleFormat)av_format_ctx->streams[audio_stream_index]
                ->codecpar->format) {
    case AV_SAMPLE_FMT_U8:
    case AV_SAMPLE_FMT_U8P:
      audio_format = AV_SAMPLE_FMT_U8;
      audio_sample_size = 1;
      break;

    case AV_SAMPLE_FMT_S16:
    case AV_SAMPLE_FMT_S16P:
      audio_format = AV_SAMPLE_FMT_S16;
      audio_sample_size = 2;
      break;

    case AV_SAMPLE_FMT_S32:
    case AV_SAMPLE_FMT_S32P:
      audio_format = AV_SAMPLE_FMT_S32;
      audio_sample_size = 4;
      break;

    case AV_SAMPLE_FMT_FLT:
    case AV_SAMPLE_FMT_FLTP:
      audio_format = AV_SAMPLE_FMT_FLT;
      audio_sample_size = 4;
      break;

    default:
      audio_format = AV_SAMPLE_FMT_FLT;
      audio_sample_size = 4;
      break;
    }

    response = swr_alloc_set_opts2(
        &swr_audio_resampler, &av_audio_codec_params->ch_layout, audio_format,
        av_audio_codec_params->sample_rate, &av_audio_codec_params->ch_layout,
        (AVSampleFormat)av_audio_codec_params->format,
        av_audio_codec_params->sample_rate, 0, nullptr);
    if (response != 0) {
      fprintf(stderr, "Couldn't allocate SwrContext\n");
      return -1;
    }

    // Should be set when decoding
    av_audio_codec_ctx->pkt_timebase =
        av_format_ctx->streams[audio_stream_index]->time_base;

    audio_time_base = av_format_ctx->streams[audio_stream_index]->time_base;
    audio_channel_count = av_audio_codec_params->ch_layout.nb_channels;
    audio_sample_rate = av_audio_codec_params->sample_rate;

    if (reopen_fifo) {
      // Reset values if audio was previously opened
      audio_frames_consumed = 0;
      audio_time = 0;

      response = audio_fifo.init(audio_format,
                                 av_audio_codec_params->ch_layout.nb_channels,
                                 av_audio_codec_params->sample_rate * 5);
      if (response != 0) {
        fprintf(stderr, "Couldn't allocate audio fifo\n");
        return -1;
      }
    }

    if (!audio_retry) {
      audio_opened = true;
    }

    PrintAudioInfo();

    return 0;
  }

  void CloseAudio(bool clear_fifo) {
    avcodec_free_context(&av_audio_codec_ctx);
    swr_free(&swr_audio_resampler);

    audio_opened = false;
    if (clear_fifo) {
      audio_fifo.clear();
      audio_fifo.free();
    }
  }

  void TimeoutReopen() {
    audio_retry = true;

    std::thread t([this]() {
      std::unique_lock<std::mutex> lock(open_mutex);

      audio_retry = true;

      StopDecodingThread();
      CloseFile();
      CloseAudio(false);

      if (!audio_opened) {
        audio_frames_consumed = 0;
        audio_fifo.init(audio_format, audio_channel_count,
                        audio_sample_rate * 5);
      }

      while (true) {
        int64_t end_audio_time =
            (double(audio_frames_consumed + audio_fifo.size()) /
             double(audio_sample_rate)) *
            1000;

        int result = OpenFile(loaded_url.c_str(), stored_auth_token.c_str(),
                              end_audio_time + time_offset);
        if (result != 0) {
          std::this_thread::sleep_for(std::chrono::seconds(1));
          continue;
        }

        result = InitAudio(false);
        if (result != 0) {
          fprintf(stderr, "Failed to reopen file %s\n", loaded_url.c_str());
          CloseFile();
          audio_retry = false;
          return;
        }

        if (!is_transcoding) {
          // Note: Zero some time don't reset, so if we try to set 0, we got
          // a little higher
          int response = av_seek_frame(
              av_format_ctx, -1,
              int64_t(end_audio_time == 0
                          ? 1953
                          : AV_TIME_BASE * double(end_audio_time) / 1000.0),
              AVSEEK_FLAG_BACKWARD);
        }

        audio_opened = true;

        break;
      }
      StartDecodingThread();
      audio_retry = false;
    });

    t.detach();
  }

  void StartDecodingThread() {
#ifdef MELODINK_PLAYER_LOG
    fprintf(stderr, "Starting thread\n");
#endif
    if (!finished_reading) {
      return;
    }

    if (!audio_opened || av_format_ctx == nullptr) {
      TimeoutReopen();

      return;
    }

    keep_loading = true;
    this->decoding_thread = std::thread(&MelodinkTrack::DecodingThread, this);
  }

  void StopDecodingThread() {
    keep_loading = false;
    finished_reading = true;
    if (decoding_thread.joinable()) {
      decoding_thread.join();
    }
  }

  int DecodingThread() {
    finished_reading = false;

    std::unique_lock<std::mutex> lock(decoding_mutex);

    if (!audio_opened || av_format_ctx == nullptr) {
      TimeoutReopen();

      finished_reading = true;
      return 0;
    }

    // Minimum amount of frames that should be pre-decoded
    size_t min_audio_queue_size;

    if (audio_opened) {
      min_audio_queue_size =
          std::max(size_t(audio_fifo.capacity() / 2), size_t(1));
    }

    int response;
    int read_packet_response;

    AVFrame *av_audio_frame = av_frame_alloc();
    if (av_audio_frame == nullptr) {
      fprintf(stderr, "Couldn't allocate resampled AVFrame\n");
      return -1;
    }

    // Used to store converted "av_audio_frame"
    AVFrame *resampled_audio_frame = av_frame_alloc();
    if (resampled_audio_frame == nullptr) {
      fprintf(stderr, "Couldn't allocate resampled AVFrame\n");
      return -1;
    }

    AVPacket read_packet;
    std::queue<AVPacket> cache_packets;
    int current_cache_size = 0;

    while (true) {
      while (true) {
        if (current_cache_size < max_preload_cache) {
          read_packet_response = av_read_frame(av_format_ctx, &read_packet);

          if (read_packet_response >= 0) {
            current_cache_size += read_packet.size;
            cache_packets.push(read_packet);
          }
        }

        if (audio_opened && audio_fifo.size() <= min_audio_queue_size) {
          break;
        }

        if (keep_loading == false) {
          while (!cache_packets.empty()) {
            AVPacket av_packet = cache_packets.front();
            current_cache_size -= av_packet.size;
            cache_packets.pop();
            av_packet_unref(&av_packet);
          }
          break;
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(10));
      }

      if (keep_loading == false) {
        break;
      }

      if (cache_packets.empty()) {
        // Return if error or end of file was encountered
        if (read_packet_response < 0) {
          if (read_packet_response == AVERROR_EOF && infinite_loop) {
            audio_frames_consumed_max =
                audio_frames_consumed + audio_fifo.size();

            std::thread t([this]() {
              std::unique_lock<std::mutex> lock(seek_mutex);
              std::unique_lock<std::mutex> lock2(open_mutex);

              StopDecodingThread();
              CloseFile();
              CloseAudio(false);

              int result =
                  OpenFile(loaded_url.c_str(), stored_auth_token.c_str(), 0);
              if (result != 0) {
                return;
              }

              result = InitAudio(false);
              if (result != 0) {
                return;
              }
              StartDecodingThread();
            });
            t.detach();

            break;
          }

#ifdef MELODINK_PLAYER_LOG
          fprintf(stderr, "Error or end of file happened\n");
          fprintf(stderr, "Exit info: %s\n", GetError(read_packet_response));
#endif

          if (read_packet_response == AVERROR(ETIMEDOUT) ||
              read_packet_response == AVERROR(EIO)) {
            TimeoutReopen();
          }
          break;
        }

        continue;
      }

      AVPacket av_packet = cache_packets.front();
      current_cache_size -= av_packet.size;
      cache_packets.pop();

      if (audio_opened && av_packet.stream_index == audio_stream_index) {
        FrameData *fd;

        av_packet.opaque_ref = av_buffer_allocz(sizeof(*fd));
        if (av_packet.opaque_ref) {
          fd = (FrameData *)av_packet.opaque_ref->data;
          fd->pkt_pos = av_packet.pos;
          fd->pkt_size = av_packet.size;
        }

        // Send packet to decode
        response = avcodec_send_packet(av_audio_codec_ctx, &av_packet);
        if (response < 0) {
          if (response != AVERROR(EAGAIN)) {
            fprintf(stderr, "Failed to decode packet\n");
            av_packet_unref(&av_packet);
            continue;
          }
        }

        // Single packet can contain multiple frames, so receive them in a loop
        while (true) {
          response = avcodec_receive_frame(av_audio_codec_ctx, av_audio_frame);
          if (response < 0) {
            if (response != AVERROR_EOF && response != AVERROR(EAGAIN)) {
              fprintf(stderr, "Something went wrong when trying to receive "
                              "decoded frame\n");
              return -1;
            }
            break;
          }

          FrameData *fd = av_audio_frame->opaque_ref
                              ? (FrameData *)av_audio_frame->opaque_ref->data
                              : NULL;

          // We don't want to do anything with empty frame
          if (fd && fd->pkt_size != -1) {
            // We have to manually copy some frame data
            resampled_audio_frame->sample_rate = av_audio_frame->sample_rate;
            resampled_audio_frame->ch_layout = av_audio_frame->ch_layout;
            resampled_audio_frame->format = (int)audio_format;

            response = swr_convert_frame(swr_audio_resampler,
                                         resampled_audio_frame, av_audio_frame);
            if (response != 0) {
              fprintf(stderr, "Couldn't resample the frame\n");
              return -1;
            }

            av_frame_unref(av_audio_frame);

            // Insert decoded audio samples
            int samples_written =
                audio_fifo.push((void **)resampled_audio_frame->data,
                                resampled_audio_frame->nb_samples);
            static size_t total_written = 0;
            total_written += samples_written;

            // Get remaining audio from previous conversion
            while (swr_get_delay(swr_audio_resampler,
                                 std::max(resampled_audio_frame->sample_rate,
                                          av_audio_frame->sample_rate)) > 0) {
              response = swr_convert_frame(swr_audio_resampler,
                                           resampled_audio_frame, nullptr);
              if (response != 0) {
                fprintf(stderr, "Couldn't resample the frame\n");
                return -1;
              }

              int samples_written =
                  audio_fifo.push((void **)resampled_audio_frame->data,
                                  resampled_audio_frame->nb_samples);
            }
          }
        }
      }
      av_packet_unref(&av_packet);
    }

    finished_reading = true;

    // Free the resources
    av_frame_free(&av_audio_frame);
    av_frame_free(&resampled_audio_frame);

#ifdef MELODINK_PLAYER_LOG
    fprintf(stderr, "Exiting thread\n");
#endif

    return 0;
  }

  int AdjustSeekedPosition(int64_t wanted_timepoint) {
    // Minimum amount of frames that should be pre-decoded
    size_t min_audio_queue_size;

    if (audio_opened || audio_retry) {
      min_audio_queue_size =
          std::max(size_t(audio_fifo.capacity() / 2), size_t(1));
    }

    int response;

    AVFrame *av_audio_frame = av_frame_alloc();
    if (av_audio_frame == nullptr) {
      fprintf(stderr, "Couldn't allocate resampled AVFrame\n");
      return -1;
    }

    // Used to store converted "av_audio_frame"
    AVFrame *resampled_audio_frame = av_frame_alloc();
    if (resampled_audio_frame == nullptr) {
      fprintf(stderr, "Couldn't allocate resampled AVFrame\n");
      return -1;
    }

    AVPacket *av_packet = av_packet_alloc();
    if (av_packet == nullptr) {
      fprintf(stderr, "Couldn't allocate resampled AVFrame\n");
      return -1;
    }

    bool audio_seeked = audio_opened || audio_retry ? false : true;

    while (true) {
      if (audio_seeked) {
        if (audio_opened || audio_retry) {
          double at = audio_time / 1000;
#ifdef MELODINK_PLAYER_LOG
          fprintf(stderr, "audio_time: %lf\n", at);
#endif
        }

        break;
      }

      // Try reading next packet
      response = av_read_frame(av_format_ctx, av_packet);

      // Return if error or end of file was encountered
      if (response < 0) {
#ifdef MELODINK_PLAYER_LOG
        fprintf(stderr, "Error or end of file happened\n");
        fprintf(stderr, "Exit info: %s\n", GetError(response));
#endif
        break;
      }

      if ((audio_opened || audio_retry) &&
          av_packet->stream_index == audio_stream_index) {
        FrameData *fd;

        av_packet->opaque_ref = av_buffer_allocz(sizeof(*fd));
        if (av_packet->opaque_ref) {
          fd = (FrameData *)av_packet->opaque_ref->data;
          fd->pkt_pos = av_packet->pos;
          fd->pkt_size = av_packet->size;
        }

        // Send packet to decode
        response = avcodec_send_packet(av_audio_codec_ctx, av_packet);
        if (response < 0) {
          if (response != AVERROR(EAGAIN)) {
            fprintf(stderr, "Failed to decode packet\n");
            return -1;
          }
        }

        // Single packet can contain multiple frames, so receive them in a loop
        while (true) {
          response = avcodec_receive_frame(av_audio_codec_ctx, av_audio_frame);
          if (response < 0) {
            if (response != AVERROR_EOF && response != AVERROR(EAGAIN)) {
              fprintf(stderr, "Something went wrong when trying to receive "
                              "decoded frame\n");
              return -1;
            }
            break;
          }

          FrameData *fd = av_audio_frame->opaque_ref
                              ? (FrameData *)av_audio_frame->opaque_ref->data
                              : NULL;

          // We don't want to do anything with empty frame
          if (fd && fd->pkt_size != -1) {
            if (CalculateAudioPts(av_audio_frame) >= wanted_timepoint) {
              // Keep track of, when the first sample starts
              if (audio_seeked == false) {
                audio_time = CalculateAudioPts(av_audio_frame);
                audio_frames_consumed =
                    size_t(audio_time / 1000 * audio_sample_rate);
              }

              audio_seeked = true;

              // We have to manually copy some frame data
              resampled_audio_frame->sample_rate = av_audio_frame->sample_rate;
              resampled_audio_frame->ch_layout = av_audio_frame->ch_layout;
              resampled_audio_frame->format = (int)audio_format;

              response = swr_convert_frame(
                  swr_audio_resampler, resampled_audio_frame, av_audio_frame);
              if (response != 0) {
                fprintf(stderr, "Couldn't resample the frame\n");
                return -1;
              }

              av_frame_unref(av_audio_frame);

              // Insert decoded audio samples
              int samples_written =
                  audio_fifo.push((void **)resampled_audio_frame->data,
                                  resampled_audio_frame->nb_samples);
              static size_t total_written = 0;
              total_written += samples_written;

              // Get remaining audio from previous conversion
              while (swr_get_delay(swr_audio_resampler,
                                   std::max(resampled_audio_frame->sample_rate,
                                            av_audio_frame->sample_rate)) > 0) {
                response = swr_convert_frame(swr_audio_resampler,
                                             resampled_audio_frame, nullptr);
                if (response != 0) {
                  fprintf(stderr, "Couldn't resample the frame\n");
                  return -1;
                }

                int samples_written =
                    audio_fifo.push((void **)resampled_audio_frame->data,
                                    resampled_audio_frame->nb_samples);
              }
            }
          }
        }
      }

      av_packet_unref(av_packet);
    }

    // Free the resources
    av_frame_free(&av_audio_frame);
    av_frame_free(&resampled_audio_frame);
    av_packet_free(&av_packet);

    return 0;
  }

  int64_t CalculateAudioPts(const AVFrame *frame) {
    return static_cast<int64_t>(
        (double(frame->best_effort_timestamp * audio_time_base.num) /
         double(audio_time_base.den)) *
        1000);
  }

public:
  MelodinkTrack() {}

  ~MelodinkTrack() { Close(); }

  void SetLoadedUrl(const char *filename) { loaded_url = filename; }

  void SetMaxPreloadCache(int64_t max_size) { max_preload_cache = max_size; }

  int Open(const char *filename, const char *auth_token) {
    std::unique_lock<std::mutex> lock(open_mutex);

    if (audio_opened) {
      return 0;
    }

    int result;

    loaded_url = filename;
    stored_auth_token = auth_token;

    result = OpenFile(filename, auth_token, 0);
    if (result != 0) {
      return result;
    }

    result = InitAudio(true);
    if (result != 0) {
      return result;
    }

    StartDecodingThread();

    return 0;
  }

  void Close() {
    StopDecodingThread();
    CloseFile();
    CloseAudio(true);
  }

  bool FinishedReading() {
    if (!audio_opened) {
      return false;
    }

    if (!finished_reading) {
      return false;
    }
    return audio_fifo.size() <= 0;
  }

  bool IsAudioRetry() { return audio_retry; }

  int64_t time_offset = 0;

  int Seek(int64_t new_time) {
    std::unique_lock<std::mutex> lock(seek_mutex);
    std::unique_lock<std::mutex> lock2(open_mutex);

    if (!audio_opened) {
      fprintf(stderr, "ERROR SEEK %s\n", loaded_url.c_str());
      return -1;
    }

    int64_t current = GetCurrentPlaybackTime();

    int64_t diff = new_time - current;

    int64_t sample_count =
        (diff * static_cast<int64_t>(audio_sample_rate)) / 1000;

    if (sample_count > 0 && sample_count <= audio_fifo.size()) {
      audio_fifo.drain(sample_count);

      audio_frames_consumed += sample_count;
      return 0;
    }

    StopDecodingThread();

    int result = 0;

    if (is_transcoding) {
      CloseFile();
      CloseAudio(true);

      int response =
          OpenFile(loaded_url.c_str(), stored_auth_token.c_str(), new_time);

      if (response >= 0) {
        result = InitAudio(true);
      } else {
        result = -1;
      }

      if (result != -1) {
        time_offset = new_time;
      }
    } else {
      // Note: Zero some time don't reset, so if we try to set 0, we got a
      // little higher
      int response = av_seek_frame(
          av_format_ctx, -1,
          int64_t(new_time == 0 ? 1953
                                : AV_TIME_BASE * double(new_time) / 1000.0),
          AVSEEK_FLAG_BACKWARD);

      if (response >= 0) {
        if (audio_opened) {
          audio_fifo.clear();
          avcodec_flush_buffers(av_audio_codec_ctx);
        }

        result = AdjustSeekedPosition(new_time);
      } else {
        result = -1;
      }
    }

    StartDecodingThread();
    return result;
  }

  void SetLoop(bool enabled) { infinite_loop = enabled; }

  int GetAudioFrame(void **output, int sample_count) {
    if (!output || !(*output) || sample_count < 0)
      return -1;

    int samples_read = audio_fifo.pop(output, sample_count);

    if (samples_read < 0)
      return samples_read;

    audio_frames_consumed += samples_read;

    if (infinite_loop && audio_frames_consumed_max != 0 &&
        audio_frames_consumed >= audio_frames_consumed_max) {
      audio_frames_consumed %= audio_frames_consumed_max;
      audio_frames_consumed_max = 0;
      time_offset = 0;
    }

    audio_time =
        (double(audio_frames_consumed) / double(audio_sample_rate)) * 1000;

    return samples_read;
  }

  bool IsAudioOpened() { return audio_opened || audio_retry; }

  void PrintAudioInfo() {
#ifndef MELODINK_PLAYER_LOG
    return;
#endif
    if (audio_opened == false) {
      fprintf(stderr, "Audio isn't open\n");
      return;
    }

    AVStream *audio_stream = av_format_ctx->streams[audio_stream_index];
    int frame_size =
        av_format_ctx->streams[audio_stream_index]->codecpar->frame_size;
    int sample_rate =
        av_format_ctx->streams[audio_stream_index]->codecpar->sample_rate;
    int channels = av_format_ctx->streams[audio_stream_index]
                       ->codecpar->ch_layout.nb_channels;
    int time_base_num = audio_stream->time_base.num;
    int time_base_den = audio_stream->time_base.den;
    int pkt_time_base_num = av_audio_codec_ctx->pkt_timebase.num;
    int pkt_time_base_den = av_audio_codec_ctx->pkt_timebase.den;
    int ctx_sample_rate = av_audio_codec_ctx->sample_rate;

    int64_t duration_origin = av_format_ctx->duration;
    int64_t duration = duration_origin / AV_TIME_BASE;
    int64_t duration_h = duration / 3600;
    int64_t duration_min = (duration % 3600) / 60;
    int64_t duration_sec = duration % 60;

    fprintf(stderr, "----------------------\n");
    fprintf(stderr, "Audio info\n");

    fprintf(stderr, "Codec: %s\n", av_audio_codec->long_name);
    fprintf(stderr, "Frame size: %i\n", frame_size);
    if (audio_opened) {
      fprintf(stderr, "Original format type: %s\n",
              av_get_sample_fmt_name(GetAudioOriginalFormat()));
    }
    fprintf(stderr, "Output format type: %s\n",
            av_get_sample_fmt_name(GetAudioOutputFormat()));
    fprintf(stderr, "Duration_origin: %" PRId64 "\n", duration_origin);
    fprintf(stderr, "Duration: %" PRId64 ":%" PRId64 ":%" PRId64 " h:min:sec\n",
            duration_h, duration_min, duration_sec);
    fprintf(stderr, "Sample rate: %i\n", sample_rate);
    fprintf(stderr, "Channels: %i\n", channels);
    fprintf(stderr, "Time base num: %i\n", time_base_num);
    fprintf(stderr, "Time base den: %i\n", time_base_den);
    fprintf(stderr, "Packet time base num: %i\n", pkt_time_base_num);
    fprintf(stderr, "Packet time base den: %i\n", pkt_time_base_den);
    fprintf(stderr, "Ctx sample rate: %i\n", ctx_sample_rate);
    fprintf(stderr, "block_align: %i\n",
            av_format_ctx->streams[audio_stream_index]->codecpar->block_align);
    fprintf(
        stderr, "initial_padding: %i\n",
        av_format_ctx->streams[audio_stream_index]->codecpar->initial_padding);
    fprintf(
        stderr, "trailing_padding: %i\n",
        av_format_ctx->streams[audio_stream_index]->codecpar->trailing_padding);
    fprintf(stderr, "seek_preroll: %i\n",
            av_format_ctx->streams[audio_stream_index]->codecpar->seek_preroll);
    fprintf(stderr, "----------------------\n");
  }

  AVSampleFormat GetAudioOutputFormat() {
    assert(audio_opened | audio_retry);

    return audio_format;
  }

  AVSampleFormat GetAudioOriginalFormat() {
    assert(audio_opened);

    return (AVSampleFormat)av_format_ctx->streams[audio_stream_index]
        ->codecpar->format;
  }

  int GetAudioSampleSize() {
    assert(audio_opened | audio_retry);

    return audio_sample_size;
  }

  int GetAudioSampleRate() {
    assert(audio_opened | audio_retry);

    return audio_sample_rate;
  }

  int GetAudioChannelCount() {
    assert(audio_opened | audio_retry);

    return audio_channel_count;
  }

  int64_t GetCurrentPlaybackTime() {
    if (!audio_opened && !audio_retry) {
      return 0;
    }

    return audio_time + time_offset;
  }

  const char *GetLoadedUrl() { return loaded_url.c_str(); }

  // av_err2str returns a temporary array. This doesn't work in gcc.
  // This function can be used as a replacement for av_err2str.
  static const char *GetError(int errnum) {
    static char str[AV_ERROR_MAX_STRING_SIZE];
    memset(str, 0, sizeof(str));
    return av_make_error_string(str, AV_ERROR_MAX_STRING_SIZE, errnum);
  }

  // This is only for `player.cc`
  std::atomic<int> player_load_count{0};
};
