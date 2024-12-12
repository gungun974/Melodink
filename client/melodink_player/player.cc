#pragma once

// #define MELODINK_PLAYER_LOG

#define MELODINK_KEEP_PREV_TRACKS 1
#define MELODINK_KEEP_NEXT_TRACKS 2

#define AVMediaType FF_AVMediaType
#include "miniaudio.h"
#undef AVMediaType

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <queue>
#include <shared_mutex>
#include <string>
#include <thread>
#include <vector>

#include "sendevent.h"
#include "track.cc"

typedef enum {
  MELODINK_PROCESSING_STATE_IDLE = 0,
  MELODINK_PROCESSING_STATE_LOADING = 0,
  MELODINK_PROCESSING_STATE_BUFFERING = 2,
  MELODINK_PROCESSING_STATE_READY = 3,
  MELODINK_PROCESSING_STATE_COMPLETED = 4,
  MELODINK_PROCESSING_STATE_ERROR = 5
} MelodinkProcessingState;

typedef enum {
  MELODINK_LOOP_MODE_NONE = 0,
  MELODINK_LOOP_MODE_ONE = 1,
  MELODINK_LOOP_MODE_ALL = 2
} MelodinkLoopMode;

class MelodinkPlayer {
private:
  MelodinkTrack *prev_track = nullptr;
  MelodinkTrack *current_track = nullptr;
  MelodinkTrack *target_current_track = nullptr;
  MelodinkTrack *next_track = nullptr;

  std::atomic<MelodinkProcessingState> state{MELODINK_PROCESSING_STATE_IDLE};

  std::atomic<MelodinkLoopMode> loop_mode{MELODINK_LOOP_MODE_NONE};

  std::string auth_token;

  void SetPlayerState(MelodinkProcessingState state) {
    if (state == this->state) {
      return;
    }

    this->state = state;

    send_event_update_state(state);
  }

  std::thread track_auto_open_thread;

  ma_device audio_device;

  bool is_paused;
  double audio_volume = 1.0f;

  std::vector<MelodinkTrack *> loaded_tracks;

  int next_track_index = -1;
  int current_track_index = -1;
  int prev_track_index = -1;

  std::thread auto_next_audio_mismatch_thread;

  std::mutex auto_next_audio_mismatch_mutex;
  std::condition_variable auto_next_audio_mismatch_conditional;

  bool IsTrackMatchDevice(MelodinkTrack *track) {
    if (!track->IsAudioOpened()) {
      return false;
    }

    switch (track->GetAudioOutputFormat()) {
    case AV_SAMPLE_FMT_U8:
      if (audio_device.playback.format != ma_format_u8) {
        return false;
      }
      break;

    case AV_SAMPLE_FMT_S16:
      if (audio_device.playback.format != ma_format_s16) {
        return false;
      }
      break;

    case AV_SAMPLE_FMT_S32:
      if (audio_device.playback.format != ma_format_s32) {
        return false;
      }
      break;

    case AV_SAMPLE_FMT_FLT:
      if (audio_device.playback.format != ma_format_f32) {
        return false;
      }
      break;
    default:
      return false;
      break;
    }

    if (audio_device.playback.channels != track->GetAudioChannelCount()) {
      return false;
    }

    return audio_device.sampleRate == track->GetAudioSampleRate();
  }

  std::mutex set_next_and_prev_audio_mutex;
  void PlayNextAudio(bool reinit) {
    std::unique_lock<std::mutex> lock(set_next_and_prev_audio_mutex);

    if (next_track == nullptr) {
      ma_device_state device_state = ma_device_get_state(&audio_device);

      if (device_state == ma_device_state_started ||
          device_state == ma_device_state_stopped) {
        reinit_miniaudio_mutex.lock();
        ma_device_stop(&audio_device);
        reinit_miniaudio_mutex.unlock();
      }

      is_paused = true;
      SetPlayerState(MELODINK_PROCESSING_STATE_COMPLETED);
      return;
    }

    bool is_track_loaded = next_track->IsAudioOpened();

    if (reinit && is_track_loaded) {
      reinit_miniaudio_mutex.lock();
      ma_device_uninit(&audio_device);
    }

    current_track_index = next_track_index;

    if (is_track_loaded) {
      current_track = next_track;
    }

    next_track = nullptr;

    if (reinit && is_track_loaded) {
      InitMiniaudio(true);
      reinit_miniaudio_mutex.unlock();
    }

    send_event_audio_changed(current_track_index);
  }

  void DontDirectPlayNextAudio() {
    std::unique_lock<std::mutex> lock(set_next_and_prev_audio_mutex);

    if (next_track == nullptr) {
      ma_device_state device_state = ma_device_get_state(&audio_device);

      if (device_state == ma_device_state_started ||
          device_state == ma_device_state_stopped) {
        reinit_miniaudio_mutex.lock();
        ma_device_stop(&audio_device);
        reinit_miniaudio_mutex.unlock();
      }

      is_paused = true;
      SetPlayerState(MELODINK_PROCESSING_STATE_COMPLETED);
      return;
    }

    current_track_index = next_track_index;

    current_track = nullptr;

    next_track = nullptr;

    send_event_audio_changed(current_track_index);
  }

  void PlayPrevAudio(bool reinit) {
    std::unique_lock<std::mutex> lock(set_next_and_prev_audio_mutex);

    if (prev_track == nullptr) {
      return;
    }

    bool is_track_loaded = prev_track->IsAudioOpened();

    if (reinit && is_track_loaded) {
      reinit_miniaudio_mutex.lock();
      ma_device_uninit(&audio_device);
    }

    current_track_index = prev_track_index;

    if (is_track_loaded) {
      current_track = prev_track;
    }

    prev_track = nullptr;

    if (reinit && is_track_loaded) {
      InitMiniaudio(true);
      reinit_miniaudio_mutex.unlock();
    }

    send_event_audio_changed(current_track_index);
  }

  std::atomic<bool> can_auto_next_audio_mismatch{false};

  void AutoNextAudioMismatchThread() {
    std::unique_lock<std::mutex> lock(auto_next_audio_mismatch_mutex);

    while (true) {
      auto_next_audio_mismatch_conditional.wait(
          lock, [this] { return can_auto_next_audio_mismatch.load(); });

      can_auto_next_audio_mismatch = false;

      PlayNextAudio(true);
    }
  }

  int64_t previous_position = -1;

  static void AudioDataCallback(ma_device *pDevice, void *pOutput,
                                const void *pInput, ma_uint32 frameCount) {
    MelodinkPlayer *player =
        reinterpret_cast<MelodinkPlayer *>(pDevice->pUserData);

    PlayAudioData(pDevice, player, pOutput, frameCount, true);

    if (player->current_track != nullptr &&
        player->loop_mode == MELODINK_LOOP_MODE_ONE) {
      int64_t current_position =
          player->current_track->GetCurrentPlaybackTime();

      if (current_position < player->previous_position) {
        send_event_update_state(player->state);
      }
      player->previous_position = current_position;
    }

    (void)pInput;
  }

  static void PlayAudioData(ma_device *pDevice, MelodinkPlayer *player,
                            void *pOutput, ma_uint32 frameCount,
                            bool can_direct_play_next) {
    if (player->current_track == nullptr) {
      return;
    }

    int frame_read = player->current_track->GetAudioFrame(&pOutput, frameCount);

    if (frame_read > 0) {
      player->SetPlayerState(MELODINK_PROCESSING_STATE_READY);
    }

    if (frame_read < 0) {
      return;
    }

    int remaining_frame = frameCount - frame_read;

    if (remaining_frame == 0) {
      return;
    }

    if (!player->current_track->FinishedReading()) {
      player->SetPlayerState(MELODINK_PROCESSING_STATE_BUFFERING);
      return;
    }

    uint8_t *pOutputByte = static_cast<uint8_t *>(pOutput);

    if (!can_direct_play_next) {
      return;
    }

    if (player->next_track != nullptr) {
      if (!player->next_track->IsAudioOpened()) {
        player->DontDirectPlayNextAudio();
        return;
      }

      if (player->current_track->GetCurrentPlaybackTime() < 100) {
        return;
      }

      if (player->IsTrackMatchDevice(player->next_track)) {
        uint8_t *pOutputByteOffset = pOutputByte +=
            player->current_track->GetAudioChannelCount() *
            player->current_track->GetAudioSampleSize() * frame_read;

        player->PlayNextAudio(false);
        PlayAudioData(pDevice, player, pOutputByteOffset, remaining_frame,
                      false);
        return;
      }
    }

    player->can_auto_next_audio_mismatch = true;

    player->auto_next_audio_mismatch_conditional.notify_one();
  }

  std::mutex reinit_miniaudio_mutex;

  int InitMiniaudio(bool start_audio) {
    if (current_track != nullptr) {

      switch (current_track->GetAudioOutputFormat()) {
      case AV_SAMPLE_FMT_U8:
        audio_device_config.playback.format = ma_format_u8;
        break;

      case AV_SAMPLE_FMT_S16:
        audio_device_config.playback.format = ma_format_s16;
        break;

      case AV_SAMPLE_FMT_S32:
        audio_device_config.playback.format = ma_format_s32;
        break;

      case AV_SAMPLE_FMT_FLT:
        audio_device_config.playback.format = ma_format_f32;
        break;

      default:
        return -1;
        break;
      }

      audio_device_config.playback.channels =
          current_track->GetAudioChannelCount();
      audio_device_config.sampleRate = current_track->GetAudioSampleRate();
    }

    audio_device_config.pUserData = this;

    audio_device_config.pulse.pStreamNamePlayback = "Melodink Player";

    audio_device_config.dataCallback = &MelodinkPlayer::AudioDataCallback;

    if (ma_device_init(NULL, &audio_device_config, &audio_device) !=
        MA_SUCCESS) {
      return -1;
    }

    if (start_audio) {
      if (ma_device_start(&audio_device) != MA_SUCCESS) {
        return -1;
      }

      is_paused = false;
    } else {
      is_paused = true;
    }

    ma_device_set_master_volume(&audio_device, audio_volume);

    return 0;
  }

  typedef std::shared_mutex Lock;
  typedef std::unique_lock<Lock> WriteLock;
  typedef std::shared_lock<Lock> ReadLock;

  Lock loaded_tracks_lock;

  std::queue<MelodinkTrack *> track_auto_open_queue;

  MelodinkTrack *LoadTrack(const char *url) {
    MelodinkTrack *new_track = new MelodinkTrack;

    new_track->player_load_count += 1;

    new_track->SetLoadedUrl(url);

    new_track->player_load_count += 1;
    track_auto_open_queue.push(new_track);

    loaded_tracks.push_back(new_track);

    return new_track;
  }

  void TrackAutoOpenThread() {
    while (true) {
      while (track_auto_open_queue.empty()) {
        std::this_thread::sleep_for(std::chrono::microseconds(10));
      }

      MelodinkTrack *track = track_auto_open_queue.front();
      track_auto_open_queue.pop();

      const char *url = track->GetLoadedUrl();

#ifdef MELODINK_PLAYER_LOG
      fprintf(stderr, "OPEN %s\n", url);
#endif

      track->Open(url, auth_token.c_str());
      track->player_load_count -= 1;
#ifdef MELODINK_PLAYER_LOG
      fprintf(stderr, "FINISH %s\n", url);
#endif
    }
  }

  MelodinkTrack *GetTrack(const char *url) {
    {
      ReadLock r_lock(loaded_tracks_lock);
      for (size_t i = 0; i < loaded_tracks.size(); ++i) {
        if (strcmp(url, loaded_tracks[i]->GetLoadedUrl()) == 0) {
          loaded_tracks[i]->player_load_count += 1;
          return loaded_tracks[i];
        }
      }
    }

    WriteLock w_lock(loaded_tracks_lock);

    return LoadTrack(url);
  }

  void UnloadTracks(std::vector<std::string> previous_urls,
                    std::vector<std::string> next_urls) {
    WriteLock w_lock(loaded_tracks_lock);
    for (size_t i = loaded_tracks.size(); i > 0; --i) {
      size_t index = i - 1;
      MelodinkTrack *track = loaded_tracks[index];

      if (track->player_load_count != 0) {
        continue;
      }

      if (track == current_track) {
        continue;
      }

      if (track == next_track) {
        continue;
      }

      if (track == prev_track) {
        continue;
      }

      bool should_skip = false;

      size_t start_previous =
          previous_urls.size() > MELODINK_KEEP_PREV_TRACKS
              ? previous_urls.size() - MELODINK_KEEP_PREV_TRACKS
              : 0;
      for (size_t j = start_previous; j < previous_urls.size(); ++j) {
        if (strcmp(track->GetLoadedUrl(), previous_urls[j].c_str()) == 0) {
          should_skip = true;
          break;
        }
      }

      if (should_skip) {
        continue;
      }

      size_t end_next = next_urls.size() > MELODINK_KEEP_NEXT_TRACKS
                            ? MELODINK_KEEP_NEXT_TRACKS
                            : next_urls.size();
      for (size_t j = 0; j < end_next; ++j) {
        if (strcmp(track->GetLoadedUrl(), next_urls[j].c_str()) == 0) {
          should_skip = true;
          break;
        }
      }

      if (should_skip) {
        continue;
      }

      loaded_tracks.erase(loaded_tracks.begin() + index);
      delete track;
    }
  }

  void SetAudioError() {
    current_track = nullptr;

    ma_device_state device_state = ma_device_get_state(&audio_device);

    if (device_state == ma_device_state_started ||
        device_state == ma_device_state_stopped) {
      reinit_miniaudio_mutex.lock();
      ma_device_stop(&audio_device);
      reinit_miniaudio_mutex.unlock();
    }

    is_paused = true;

    SetPlayerState(MELODINK_PROCESSING_STATE_ERROR);
  }

  void SetAudioCurrent(MelodinkTrack *new_current_track) {
    new_current_track->SetLoop(loop_mode == MELODINK_LOOP_MODE_ONE);

    new_current_track->SetMaxPreloadCache(20 * 1024 * 1024); // 20MiB

    if (new_current_track != current_track) {
      if (new_current_track->GetCurrentPlaybackTime() != 0) {
        new_current_track->player_load_count += 1;
        std::thread t([new_current_track]() {
          new_current_track->Seek(0);
          new_current_track->player_load_count -= 1;
        });
        t.detach();
      }
    }

    if (!IsTrackMatchDevice(new_current_track)) {
      reinit_miniaudio_mutex.lock();
      ma_device_state device_state = ma_device_get_state(&audio_device);

      if (device_state == ma_device_state_started ||
          device_state == ma_device_state_stopped) {
        ma_device_stop(&audio_device);
      }

      if (!new_current_track->IsAudioOpened()) {
        current_track = nullptr;

        ma_device_state device_state = ma_device_get_state(&audio_device);

        if (device_state == ma_device_state_started ||
            device_state == ma_device_state_stopped) {
          ma_device_stop(&audio_device);
        }

        is_paused = true;

        SetPlayerState(MELODINK_PROCESSING_STATE_ERROR);
      } else {
        ma_device_uninit(&audio_device);

        current_track = new_current_track;

        InitMiniaudio(!is_paused);
      }

      reinit_miniaudio_mutex.unlock();
    } else {
      current_track = new_current_track;
    }
  }

  void SetAudioPrev(std::vector<std::string> previous_urls,
                    std::vector<std::string> next_urls) {
    if (previous_urls.size() > 1) {
      MelodinkTrack *new_prev_track =
          GetTrack(previous_urls[previous_urls.size() - 2].c_str());
      prev_track = new_prev_track;

      prev_track->SetMaxPreloadCache(100 * 1024); // 100KiB

      if (new_prev_track->GetCurrentPlaybackTime() != 0) {
        new_prev_track->player_load_count += 1;
        std::thread t([new_prev_track]() {
          new_prev_track->Seek(0);
          new_prev_track->player_load_count -= 1;
        });
        t.detach();
      }
      new_prev_track->player_load_count -= 1;
    }
  }

  void SetAudioNext(std::vector<std::string> previous_urls,
                    std::vector<std::string> next_urls) {
    if (next_urls.size() == 0) {
      if (loop_mode == MELODINK_LOOP_MODE_ALL) {
        next_track_index = 0;
        MelodinkTrack *new_next_track = GetTrack(previous_urls[0].c_str());
        next_track = new_next_track;

        next_track->SetMaxPreloadCache(100 * 1024); // 100KiB

        if (new_next_track->GetCurrentPlaybackTime() != 0) {
          new_next_track->player_load_count += 1;
          std::thread t([new_next_track]() {
            new_next_track->Seek(0);
            new_next_track->player_load_count -= 1;
          });
          t.detach();
        }
        new_next_track->player_load_count -= 1;

      } else {
        next_track = nullptr;
      }
    } else {
      MelodinkTrack *new_next_track = GetTrack(next_urls[0].c_str());
      next_track = new_next_track;

      next_track->SetMaxPreloadCache(100 * 1024); // 100KiB

      if (new_next_track->GetCurrentPlaybackTime() != 0) {
        new_next_track->player_load_count += 1;
        std::thread t([new_next_track]() {
          new_next_track->Seek(0);
          new_next_track->player_load_count -= 1;
        });
        t.detach();
      }
      new_next_track->player_load_count -= 1;
    }
  }

  ma_device_config audio_device_config;

public:
  MelodinkPlayer() {
#ifndef MELODINK_PLAYER_LOG
    av_log_set_level(AV_LOG_QUIET);
#endif

    reinit_miniaudio_mutex.lock();
    audio_device_config = ma_device_config_init(ma_device_type_playback);
    InitMiniaudio(false);
    reinit_miniaudio_mutex.unlock();

    auto_next_audio_mismatch_thread =
        std::thread(&MelodinkPlayer::AutoNextAudioMismatchThread, this);

    track_auto_open_thread =
        std::thread(&MelodinkPlayer::TrackAutoOpenThread, this);
  }

  ~MelodinkPlayer() {}

  void Play() {
    if (!is_paused) {
      return;
    }

    ma_device_state device_state = ma_device_get_state(&audio_device);

    if (device_state == ma_device_state_started ||
        device_state == ma_device_state_stopped) {
      reinit_miniaudio_mutex.lock();
#ifndef __ANDROID__
      ma_device_start(&audio_device);
#else
      // On Android device "start" can sometime just don't work
      ma_device_uninit(&audio_device);
      InitMiniaudio(true);
#endif
      reinit_miniaudio_mutex.unlock();
    }

    is_paused = false;
  }

  void Pause() {
    if (is_paused) {
      return;
    }

    ma_device_state device_state = ma_device_get_state(&audio_device);

    if (device_state == ma_device_state_started ||
        device_state == ma_device_state_stopped) {
      reinit_miniaudio_mutex.lock();
      ma_device_stop(&audio_device);
      reinit_miniaudio_mutex.unlock();
    }

    is_paused = true;
  }

  void Next() { PlayNextAudio(true); }

  void Prev() { PlayPrevAudio(true); }

  std::atomic<int64_t> seek_duration{-1};

  void Seek(int64_t position_ms) {
    seek_duration = position_ms;

    std::thread t([this, position_ms]() {
      if (current_track == nullptr) {
        seek_duration = -1;
        return;
      }

      seek_duration = position_ms;

      state = MELODINK_PROCESSING_STATE_BUFFERING;

      send_event_update_state(state);

      current_track->player_load_count += 1;

      ma_device_state device_state = ma_device_get_state(&audio_device);

      if (device_state == ma_device_state_started ||
          device_state == ma_device_state_stopped) {
        reinit_miniaudio_mutex.lock();
        ma_device_stop(&audio_device);
        reinit_miniaudio_mutex.unlock();
      }

      current_track->Seek(position_ms);

      seek_duration = -1;

      state = MELODINK_PROCESSING_STATE_READY;

      send_event_update_state(state);

      if (!is_paused) {
        reinit_miniaudio_mutex.lock();
#ifndef __ANDROID__
        ma_device_start(&audio_device);
#else
        // On Android device "start" can sometime just don't work
        ma_device_uninit(&audio_device);
        InitMiniaudio(true);
#endif
        reinit_miniaudio_mutex.unlock();
      }

      current_track->player_load_count -= 1;
    });

    t.detach();
  }

  void SetAudios(std::vector<const char *> raw_previous_urls,
                 std::vector<const char *> raw_next_urls) {
    std::vector<std::string> previous_urls;
    previous_urls.reserve(raw_previous_urls.size());
    for (const auto &cstr : raw_previous_urls) {
      previous_urls.emplace_back(cstr);
    }

    std::vector<std::string> next_urls;
    next_urls.reserve(raw_next_urls.size());
    for (const auto &cstr : raw_next_urls) {
      next_urls.emplace_back(cstr);
    }

    if (previous_urls.size() == 0) {
      current_track = nullptr;
      UnloadTracks(previous_urls, next_urls);
      return;
    }

    const char *current_url = previous_urls.back().c_str();

    current_track_index = previous_urls.size() - 1;
    prev_track_index = current_track_index - 1;
    next_track_index = current_track_index + 1;

    send_event_audio_changed(current_track_index);

    MelodinkTrack *new_current_track = GetTrack(current_url);

    if (!new_current_track->IsAudioOpened()) {
      current_track = nullptr;
      target_current_track = new_current_track;

      SetPlayerState(MELODINK_PROCESSING_STATE_BUFFERING);

      new_current_track->player_load_count += 1;

      std::thread t([new_current_track, this]() {
        const char *url = new_current_track->GetLoadedUrl();

#ifdef MELODINK_PLAYER_LOG
        fprintf(stderr, "OPEN late %s\n", url);
#endif
        new_current_track->Open(url, auth_token.c_str());
#ifdef MELODINK_PLAYER_LOG
        fprintf(stderr, "FINISH late %s\n", url);
#endif

        if (target_current_track == new_current_track) {
          if (!new_current_track->IsAudioOpened()) {
            SetAudioError();
          } else {
            SetAudioCurrent(new_current_track);
          }
        }

        new_current_track->player_load_count -= 1;
      });

      t.detach();
    } else {
      SetAudioCurrent(new_current_track);
    }

    new_current_track->player_load_count -= 1;

    SetAudioPrev(previous_urls, next_urls);

    SetAudioNext(previous_urls, next_urls);

    size_t start_previous =
        previous_urls.size() > MELODINK_KEEP_PREV_TRACKS
            ? previous_urls.size() - MELODINK_KEEP_PREV_TRACKS
            : 0;
    for (size_t j = start_previous; j < previous_urls.size(); ++j) {
      MelodinkTrack *track = GetTrack(previous_urls[j].c_str());
      track->SetMaxPreloadCache(100 * 1024); // 100KiB
      track->player_load_count -= 1;
    }

    size_t end_next = next_urls.size() > MELODINK_KEEP_NEXT_TRACKS
                          ? MELODINK_KEEP_NEXT_TRACKS
                          : next_urls.size();
    for (size_t j = 0; j < end_next; ++j) {
      MelodinkTrack *track = GetTrack(next_urls[j].c_str());
      track->SetMaxPreloadCache(100 * 1024); // 100KiB
      track->player_load_count -= 1;
    }

    UnloadTracks(previous_urls, next_urls);
  }

  int64_t GetCurrentTrackPos() { return current_track_index; }

  int64_t GetCurrentPosition() {
    if (current_track == nullptr) {
      return 0;
    }

    if (seek_duration >= 0) {
      return seek_duration;
    }

    return current_track->GetCurrentPlaybackTime();
  }

  int64_t GetCurrentBufferedPosition() {
    // TODO:
    return 0;
  }

  bool GetCurrentPlaying() { return !is_paused; }

  void SetLoopMode(MelodinkLoopMode loop) {
    loop_mode = loop;

    return;
  }

  MelodinkLoopMode GetCurrentLoopMode() { return loop_mode; }

  MelodinkProcessingState GetCurrentPlayerState() { return state; }

  void SetAuthToken(const char *auth_token) {
    this->auth_token = auth_token;

    return;
  }

  void SetVolume(double volume) {
    double clamped_volume = volume;

    if (volume < 0.0f)
      clamped_volume = 0.0f;
    else if (volume > 1.0f)
      clamped_volume = 1.0f;

    audio_volume = clamped_volume;
    ma_device_set_master_volume(&audio_device, clamped_volume);
  }

  double GetVolume() { return audio_volume; }
};
