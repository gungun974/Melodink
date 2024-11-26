#pragma once

extern "C" {
#include <libavutil/audio_fifo.h>
#include <libavutil/avutil.h>
}

#include <mutex>

class AudioFifo {
private:
  AVAudioFifo *_fifo = nullptr;
  mutable std::mutex _mut;

public:
  AudioFifo() {}

  ~AudioFifo() {
    clear();
    free();
  }

  int init(AVSampleFormat format, int channels, int capacity) {
    if (capacity == 0 || channels == 0)
      return -1;

    if (_fifo != nullptr) {
      clear();
      free();
    }

    _fifo = av_audio_fifo_alloc(format, channels, capacity);

    if (_fifo == nullptr)
      return -1;

    return 0;
  }

  int push(void **data, int samples) {
    std::lock_guard<std::mutex> lock(_mut);

    if (_fifo == nullptr) {
      return -1;
    }

    int space = av_audio_fifo_space(_fifo);

    if (samples > space) {
      av_audio_fifo_drain(_fifo,
                          std::min(av_audio_fifo_size(_fifo), samples - space));
    }

    return av_audio_fifo_write(_fifo, data, samples);
  }

  int pop(void **data, int samples) {
    std::unique_lock<std::mutex> lock(_mut);
    if (_fifo == nullptr) {
      return -1;
    }

    return av_audio_fifo_read(_fifo, data, samples);
  }

  void drain(int samples) {
    std::unique_lock<std::mutex> lock(_mut);
    av_audio_fifo_drain(_fifo, samples);
  }

  int size() {
    std::unique_lock<std::mutex> lock(_mut);
    return av_audio_fifo_size(_fifo);
  }

  int capacity() {
    std::unique_lock<std::mutex> lock(_mut);
    return av_audio_fifo_space(_fifo) + av_audio_fifo_size(_fifo);
  }

  void clear() {
    std::unique_lock<std::mutex> lock(_mut);
    if (_fifo != nullptr)
      av_audio_fifo_drain(_fifo, av_audio_fifo_size(_fifo));
  }

  void free() {
    std::unique_lock<std::mutex> lock(_mut);
    av_audio_fifo_free(_fifo);
    _fifo = nullptr;
  }
};
