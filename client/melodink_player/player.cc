#pragma once

// #define MELODINK_PLAYER_LOG

#define MELODINK_KEEP_PREV_TRACKS 5
#define MELODINK_KEEP_NEXT_TRACKS 8

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

  std::thread set_audio_thread;
  std::thread set_audio_thread2;

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

  void PlayNextAudio(bool reinit) {
    if (can_change_track != 0) {
      return;
    }

    std::unique_lock<std::mutex> lock(set_audio_mutex);

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

  void PlayPrevAudio(bool reinit) {
    if (can_change_track != 0) {
      return;
    }

    std::unique_lock<std::mutex> lock(set_audio_mutex);

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

  void AutoNextAudioMismatchThread() {
    std::unique_lock<std::mutex> lock(auto_next_audio_mismatch_mutex);

    while (true) {
      auto_next_audio_mismatch_conditional.wait(lock);

      PlayNextAudio(true);
    }
  }

  std::atomic<int64_t> last_set_audio_id{0};
  std::mutex set_audio_mutex;
  std::atomic<int64_t> can_change_track{0};

  struct SetAudioRequest {
    std::vector<std::string> previous_urls;
    std::vector<std::string> next_urls;
  };

  std::queue<std::shared_ptr<SetAudioRequest>> set_audio_queue;
  std::mutex set_audio_queue_mutex;
  std::mutex set_audio_queue_write_mutex;

  void SetAudioThread() {
    while (true) {
      set_audio_queue_mutex.lock();
      while (set_audio_queue.empty()) {
        std::this_thread::sleep_for(std::chrono::microseconds(10));
      }

      SetAudioRequest request;

      while (!set_audio_queue.empty()) {
        request = *set_audio_queue.front();
        set_audio_queue.pop();
      }

      can_change_track += 1;

      int64_t current_set_audio_id = last_set_audio_id.fetch_add(1);

      std::unique_lock<std::mutex> lock(set_audio_mutex);
      set_audio_queue_mutex.unlock();

      if (last_set_audio_id.load() - 1 != current_set_audio_id) {
        can_change_track -= 1;
        continue;
      }

      if (request.previous_urls.size() == 0) {
        current_track = nullptr;
        if (last_set_audio_id.load() - 1 != current_set_audio_id) {
          can_change_track -= 1;
          continue;
        }
        UnloadTracks(request.previous_urls, request.next_urls);
        can_change_track -= 1;
        continue;
      }

      const char *current_url = request.previous_urls.back().c_str();

      if (last_set_audio_id.load() - 1 != current_set_audio_id) {
        can_change_track -= 1;
        continue;
      }

      current_track_index = request.previous_urls.size() - 1;
      prev_track_index = current_track_index - 1;
      next_track_index = current_track_index + 1;

      send_event_audio_changed(current_track_index);

      MelodinkTrack *new_current_track = GetTrack(current_url);

      if (last_set_audio_id.load() - 1 != current_set_audio_id) {
        new_current_track->player_load_count -= 1;
        can_change_track -= 1;
        continue;
      }

      if (!new_current_track->IsAudioOpened()) {
        current_track = nullptr;

        SetAudioPrev(request.previous_urls, request.next_urls);

        if (last_set_audio_id.load() - 1 != current_set_audio_id) {
          new_current_track->player_load_count -= 1;
          can_change_track -= 1;
          continue;
        }

        SetAudioNext(request.previous_urls, request.next_urls);

        if (last_set_audio_id.load() - 1 != current_set_audio_id) {
          new_current_track->player_load_count -= 1;
          can_change_track -= 1;
          continue;
        }

        SetPlayerState(MELODINK_PROCESSING_STATE_BUFFERING);

        set_audio_mutex.unlock();

        can_change_track -= 1;

        std::shared_ptr<std::atomic<bool>> is_loading_finish =
            std::make_shared<std::atomic<bool>>(false);

        std::thread t(
            [new_current_track, this, current_url, is_loading_finish]() {
#ifdef MELODINK_PLAYER_LOG
              fprintf(stderr, "OPEN late %s\n", current_url);
#endif
              new_current_track->player_load_count += 1;
              new_current_track->Open(current_url, auth_token.c_str());
              new_current_track->player_load_count -= 1;
              *is_loading_finish = true;
#ifdef MELODINK_PLAYER_LOG
              fprintf(stderr, "FINISH late %s\n", current_url);
#endif
            });

        t.detach();

        while (!*is_loading_finish) {
          if (last_set_audio_id.load() - 1 != current_set_audio_id) {
            break;
          }

          std::this_thread::sleep_for(std::chrono::microseconds(10));
        }

        if (last_set_audio_id.load() - 1 != current_set_audio_id) {
          new_current_track->player_load_count -= 1;
          continue;
        }

        can_change_track += 1;
        set_audio_mutex.lock();
      }

      if (last_set_audio_id.load() - 1 != current_set_audio_id) {
        new_current_track->player_load_count -= 1;
        can_change_track -= 1;
        continue;
      }

      if (!new_current_track->IsAudioOpened()) {
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
      } else {
        new_current_track->SetLoop(loop_mode == MELODINK_LOOP_MODE_ONE);

        if (new_current_track != current_track) {
          if (new_current_track->GetCurrentPlaybackTime() != 0.0) {
            new_current_track->Seek(0);
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

      new_current_track->player_load_count -= 1;

      SetAudioPrev(request.previous_urls, request.next_urls);

      if (last_set_audio_id.load() - 1 != current_set_audio_id) {
        can_change_track -= 1;
        continue;
      }

      SetAudioNext(request.previous_urls, request.next_urls);

      if (last_set_audio_id.load() - 1 != current_set_audio_id) {
        can_change_track -= 1;
        continue;
      }

      size_t start_previous =
          request.previous_urls.size() > MELODINK_KEEP_PREV_TRACKS
              ? request.previous_urls.size() - MELODINK_KEEP_PREV_TRACKS
              : 0;
      for (size_t j = start_previous; j < request.previous_urls.size(); ++j) {
        if (last_set_audio_id.load() - 1 != current_set_audio_id) {
          break;
        }
        MelodinkTrack *track = GetTrack(request.previous_urls[j].c_str());
        track->player_load_count -= 1;
      }

      if (last_set_audio_id.load() - 1 != current_set_audio_id) {
        can_change_track -= 1;
        continue;
      }

      size_t end_next = request.next_urls.size() > MELODINK_KEEP_NEXT_TRACKS
                            ? MELODINK_KEEP_NEXT_TRACKS
                            : request.next_urls.size();
      for (size_t j = 0; j < end_next; ++j) {
        if (last_set_audio_id.load() - 1 != current_set_audio_id) {
          break;
        }
        MelodinkTrack *track = GetTrack(request.next_urls[j].c_str());
        track->player_load_count -= 1;
      }

      if (last_set_audio_id.load() - 1 != current_set_audio_id) {
        can_change_track -= 1;
        continue;
      }
      UnloadTracks(request.previous_urls, request.next_urls);
      can_change_track -= 1;
    }
  }

  void SetAudioPrev(std::vector<std::string> previous_urls,
                    std::vector<std::string> next_urls) {
    if (previous_urls.size() > 1) {
      prev_track = GetTrack(previous_urls[previous_urls.size() - 2].c_str());
      if (prev_track->GetCurrentPlaybackTime() != 0.0) {
        prev_track->Seek(0);
      }
      prev_track->player_load_count -= 1;
    }
  }

  void SetAudioNext(std::vector<std::string> previous_urls,
                    std::vector<std::string> next_urls) {
    if (next_urls.size() == 0) {
      if (loop_mode == MELODINK_LOOP_MODE_ALL) {
        next_track_index = 0;
        next_track = GetTrack(previous_urls[0].c_str());
        if (next_track->GetCurrentPlaybackTime() != 0.0) {
          next_track->Seek(0);
        }
        next_track->player_load_count -= 1;

      } else {
        next_track = nullptr;
      }
    } else {
      next_track = GetTrack(next_urls[0].c_str());
      if (next_track->GetCurrentPlaybackTime() != 0.0) {
        next_track->Seek(0);
      }
      next_track->player_load_count -= 1;
    }
  }

  double previous_position = -1;

  static void AudioDataCallback(ma_device *pDevice, void *pOutput,
                                const void *pInput, ma_uint32 frameCount) {
    MelodinkPlayer *player =
        reinterpret_cast<MelodinkPlayer *>(pDevice->pUserData);

    PlayAudioData(pDevice, player, pOutput, frameCount, true);

    if (player->current_track != nullptr &&
        player->loop_mode == MELODINK_LOOP_MODE_ONE) {
      double current_position = player->current_track->GetCurrentPlaybackTime();

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

    if (player->can_change_track != 0) {
      return;
    }

    if (player->next_track != nullptr) {
      if (!player->next_track->IsAudioOpened()) {
        return;
      }

      if (player->current_track->GetCurrentPlaybackTime() < 0.1) {
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

    is_paused = false;

    if (start_audio) {
      if (ma_device_start(&audio_device) != MA_SUCCESS) {
        return -1;
      }
    }

    ma_device_set_master_volume(&audio_device, audio_volume);

    return 0;
  }

  typedef std::shared_mutex Lock;
  typedef std::unique_lock<Lock> WriteLock;
  typedef std::shared_lock<Lock> ReadLock;

  Lock loaded_tracks_lock;

  std::mutex load_track_mutex;
  std::condition_variable load_track_conditional;

  std::atomic<int> parallel_loading{0};

  MelodinkTrack *LoadTrack(const char *url) {
    MelodinkTrack *new_track = new MelodinkTrack;

    new_track->player_load_count += 1;

    new_track->SetLoadedUrl(url);

    std::unique_lock<std::mutex> lock(load_track_mutex);
    while (parallel_loading > 15) {
      load_track_conditional.wait(lock);
    }

    parallel_loading += 1;

    std::thread t([new_track, this, url]() {
#ifdef MELODINK_PLAYER_LOG
      fprintf(stderr, "OPEN %s\n", url);
#endif
      new_track->player_load_count += 1;
      new_track->Open(new_track->GetLoadedUrl(), auth_token.c_str());
      new_track->player_load_count -= 1;
      parallel_loading -= 1;
      load_track_conditional.notify_one();
#ifdef MELODINK_PLAYER_LOG
      fprintf(stderr, "FINISH %s\n", url);
#endif
    });

    t.detach();

    loaded_tracks.push_back(new_track);

    return new_track;
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

    set_audio_thread = std::thread(&MelodinkPlayer::SetAudioThread, this);
    set_audio_thread2 = std::thread(&MelodinkPlayer::SetAudioThread, this);
  }

  ~MelodinkPlayer() {}

  void Play() {
    if (current_track == nullptr) {
      return;
    }

    if (!current_track->IsAudioOpened()) {
      return;
    }

    if (!is_paused) {
      return;
    }

    ma_device_state device_state = ma_device_get_state(&audio_device);

    if (device_state == ma_device_state_started ||
        device_state == ma_device_state_stopped) {
      reinit_miniaudio_mutex.lock();
      ma_device_start(&audio_device);
      reinit_miniaudio_mutex.unlock();
    }

    is_paused = false;
  }

  void Pause() {
    if (current_track == nullptr) {
      return;
    }

    if (!current_track->IsAudioOpened()) {
      return;
    }

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
    MelodinkTrack *static_current_track = current_track;

    if (static_current_track == nullptr) {
      return;
    }

    seek_duration = position_ms;

    state = MELODINK_PROCESSING_STATE_BUFFERING;

    send_event_update_state(state);

    std::thread t([this, position_ms, static_current_track]() {
      std::unique_lock<std::mutex> lock(set_audio_mutex);
      WriteLock w_lock(loaded_tracks_lock);

      if (current_track == nullptr) {
        seek_duration = -1;

        state = MELODINK_PROCESSING_STATE_READY;

        send_event_update_state(state);
        return;
      }

      if (current_track != static_current_track) {
        seek_duration = -1;

        state = MELODINK_PROCESSING_STATE_READY;

        send_event_update_state(state);
        return;
      }

      can_change_track += 1;
      current_track->player_load_count += 1;

      double position_seconds = position_ms / 1000.0;

      ma_device_state device_state = ma_device_get_state(&audio_device);

      if (device_state == ma_device_state_started ||
          device_state == ma_device_state_stopped) {
        reinit_miniaudio_mutex.lock();
        ma_device_stop(&audio_device);
        reinit_miniaudio_mutex.unlock();
      }

      current_track->Seek(position_seconds);

      seek_duration = -1;

      state = MELODINK_PROCESSING_STATE_READY;

      send_event_update_state(state);

      if (!is_paused) {
        reinit_miniaudio_mutex.lock();
        ma_device_start(&audio_device);
        reinit_miniaudio_mutex.unlock();
      }

      current_track->player_load_count -= 1;
      can_change_track -= 1;
    });

    t.detach();
  }

  void SetAudios(std::vector<const char *> previous_urls,
                 std::vector<const char *> next_urls) {
    std::vector<std::string> previous_urls_strings;
    previous_urls_strings.reserve(previous_urls.size());
    for (const auto &cstr : previous_urls) {
      previous_urls_strings.emplace_back(cstr);
    }

    std::vector<std::string> next_urls_strings;
    next_urls_strings.reserve(next_urls.size());
    for (const auto &cstr : next_urls) {
      next_urls_strings.emplace_back(cstr);
    }

    struct SetAudioRequest request = {previous_urls_strings, next_urls_strings};

    set_audio_queue.push(std::make_shared<SetAudioRequest>(std::move(request)));
  }

  int64_t GetCurrentTrackPos() { return current_track_index; }

  int64_t GetCurrentPosition() {
    if (current_track == nullptr) {
      return 0;
    }

    if (seek_duration >= 0) {
      return seek_duration;
    }

    return (int64_t)(current_track->GetCurrentPlaybackTime() * 1000);
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
