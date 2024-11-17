#pragma once

#include <string.h>
#include <vector>

#include <atomic>
#include <thread>

#include "client.h"
#include "sendevent.cc"

typedef enum {
  MELODINK_PROCESSING_STATE_IDLE = 0,
  MELODINK_PROCESSING_STATE_LOADING = 0,
  MELODINK_PROCESSING_STATE_BUFFERING = 2,
  MELODINK_PROCESSING_STATE_READY = 3,
  MELODINK_PROCESSING_STATE_COMPLETED = 4
} MelodinkProcessingState;

typedef enum {
  MELODINK_LOOP_MODE_NONE = 0,
  MELODINK_LOOP_MODE_ONE = 1,
  MELODINK_LOOP_MODE_ALL = 2
} MelodinkLoopMode;

class AudioPlayer {
private:
  mpv_handle *mpv;

  std::thread event_thread;
  std::atomic<bool> stop_event_thread;
  std::atomic<bool> dont_send_audio_changed;
  std::atomic<bool> is_buffering_state_change_allowed;

  MelodinkProcessingState state = MELODINK_PROCESSING_STATE_IDLE;

  void set_player_state(MelodinkProcessingState state) {
    this->state = state;

    send_event_update_state(state);
  }

  void event_loop() {
    while (!stop_event_thread.load()) {
      mpv_event *event = mpv_wait_event(mpv, 1000);
      if (event->event_id == MPV_EVENT_SHUTDOWN) {
        set_player_state(MELODINK_PROCESSING_STATE_IDLE);
        break;
      }

      if (event->event_id == MPV_EVENT_START_FILE) {
        set_player_state(MELODINK_PROCESSING_STATE_BUFFERING);
      }

      if (event->event_id == MPV_EVENT_PLAYBACK_RESTART) {
        set_player_state(MELODINK_PROCESSING_STATE_READY);
      }

      if (event->event_id == MPV_EVENT_SEEK) {
        set_player_state(MELODINK_PROCESSING_STATE_BUFFERING);
      }

      if (event->event_id == MPV_EVENT_PROPERTY_CHANGE) {
        mpv_event_property *prop = (mpv_event_property *)event->data;
        if (strcmp(prop->name, "playlist-playing-pos") == 0) {
          int64_t pos = *(int64_t *)prop->data;

          if (pos < 0) {
            continue;
          }

          if (dont_send_audio_changed.load()) {
            continue;
          }

          send_event_audio_changed(pos);
        }
        if (strcmp(prop->name, "pause") == 0) {
          int64_t paused = *(int64_t *)prop->data;

          if (paused) {
            continue;
          }
        }

        if (strcmp(prop->name, "idle-active") == 0) {
          int64_t idle = *(int64_t *)prop->data;
          if (idle) {
            set_player_state(MELODINK_PROCESSING_STATE_IDLE);
          }
        }

        if (strcmp(prop->name, "core-idle") == 0) {
          int64_t buffering = *(int64_t *)prop->data;
          if (buffering && is_buffering_state_change_allowed.load()) {
            set_player_state(MELODINK_PROCESSING_STATE_BUFFERING);
          } else {
            set_player_state(MELODINK_PROCESSING_STATE_READY);
          }

          is_buffering_state_change_allowed.store(true);
        }

        if (strcmp(prop->name, "eof-reached") == 0) {
          int64_t eof = has_eof_reached();
          if (eof) {
            set_player_state(MELODINK_PROCESSING_STATE_IDLE);
          }
        }
      }
    }
  }

public:
  AudioPlayer() {
    mpv = mpv_create();
    if (!mpv) {
      fprintf(stderr, "Could not create MPV context\n");
      exit(1);
      return;
    }

    mpv_set_option_string(mpv, "vo", "null");
    mpv_set_option_string(mpv, "no-terminal", "yes");

    mpv_set_option_string(mpv, "prefetch-playlist", "yes");
    mpv_set_option_string(mpv, "merge-files", "yes");

    mpv_set_option_string(mpv, "keep-open", "yes");

    mpv_set_option_string(mpv, "idle", "yes");

    if (mpv_initialize(mpv) < 0) {
      fprintf(stderr, "Could not initialize MPV context\n");
      exit(1);
      return;
    };

    mpv_set_option_string(mpv, "http-header-fields",
                          "User-Agent: Melodink-MPV");

    mpv_observe_property(mpv, 0, "playlist-playing-pos", MPV_FORMAT_INT64);
    mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(mpv, 0, "idle-active", MPV_FORMAT_FLAG);
    mpv_observe_property(mpv, 0, "core-idle", MPV_FORMAT_FLAG);
    mpv_observe_property(mpv, 0, "eof-reached", MPV_FORMAT_FLAG);

    event_thread = std::thread(&AudioPlayer::event_loop, this);
  }

  ~AudioPlayer() {
    stop_event_thread.store(true);
    if (event_thread.joinable()) {
      event_thread.join();
    }

    mpv_terminate_destroy(mpv);
  }

  void play() {
    const char *cmd[] = {"set", "pause", "no", NULL};
    mpv_command(mpv, cmd);
  }

  void pause() {
    is_buffering_state_change_allowed.store(false);
    const char *cmd[] = {"set", "pause", "yes", NULL};
    mpv_command(mpv, cmd);
  }

  void next() {
    const char *cmd[] = {"playlist-next", NULL};
    mpv_command(mpv, cmd);
  }

  void prev() {
    const char *cmd[] = {"playlist-prev", NULL};
    mpv_command(mpv, cmd);
  }

  void seek(int64_t position_ms) {
    set_player_state(MELODINK_PROCESSING_STATE_BUFFERING);

    double position_seconds = position_ms / 1000.0;
    mpv_set_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &position_seconds);
  }

  void get_track_url_at(int64_t index, char *result) {
    char target[255];

    sprintf(target, "playlist/%ld/filename", index);

    char *filename = NULL;
    mpv_get_property(mpv, target, MPV_FORMAT_STRING, &filename);

    if (filename) {
      strcpy(result, filename);
      mpv_free(filename);
    } else {
      strcpy(result, "");
    }
  }

  void debug() {
    char result[255];

    fprintf(stderr, "---------------\n");
    for (int i = 0; i < this->get_playlist_length(); i++) {
      this->get_track_url_at(i, result);

      fprintf(stderr, "%d : %s\n", i, result);
    }
  }

  void set_audios(std::vector<const char *> previous_urls,
                  std::vector<const char *> next_urls) {
    char result[255];

    dont_send_audio_changed.store(true);

    //!
    //! Previous audios
    //!

    // Set current audio

    int current_index = this->get_current_track_pos();

    if (current_index == -1) {
      const char *clear_cmd[] = {"playlist-clear", NULL};
      mpv_command(mpv, clear_cmd);
    }

    this->get_track_url_at(current_index, result);

    const char *play_url = previous_urls[previous_urls.size() - 1];

    if (strcmp(play_url, result) != 0) {

      std::string str = std::to_string(current_index);
      const char *cstr = str.c_str();

      if (strcmp(result, "") != 0) {
        const char *cmd[] = {"playlist-remove", cstr, NULL};
        mpv_command(mpv, cmd);
      }

      if (current_index == -1) {
        const char *cmd[] = {"loadfile", play_url, "append-play", NULL};
        mpv_command(mpv, cmd);
      } else {
        const char *cmd[] = {"loadfile", play_url, "insert-at", cstr, NULL};
        mpv_command(mpv, cmd);

        const char *cmd2[] = {"playlist-play-index", cstr, NULL};
        mpv_command(mpv, cmd2);
      }
    }

    // Set previous audios

    for (size_t i = 1; i < previous_urls.size(); i++) {
      const char *url = previous_urls[previous_urls.size() - 1 - i];

      int look_index = current_index - i;

      this->get_track_url_at(look_index, result);

      if (strcmp(url, result) != 0) {

        if (look_index < 0) {
          look_index = 0;
        }

        std::string str = std::to_string(look_index);
        const char *cstr = str.c_str();

        if (strcmp(result, "") != 0) {
          const char *cmd[] = {"playlist-remove", cstr, NULL};
          mpv_command(mpv, cmd);
        }

        const char *cmd[] = {"loadfile", url, "insert-at", cstr, NULL};
        mpv_command(mpv, cmd);
      }
    }

    if (current_index < 0) {
      current_index = 0;
    }

    // Clean old previous audios

    int last_start_index = current_index - previous_urls.size();

    while (last_start_index >= 0) {

      std::string str = std::to_string(last_start_index);
      const char *cstr = str.c_str();
      const char *cmd[] = {"playlist-remove", cstr, NULL};
      mpv_command(mpv, cmd);

      last_start_index -= 1;
    }

    //!
    //! Next audios
    //!

    current_index = previous_urls.size() - 1;

    for (size_t i = 0; i < next_urls.size(); i++) {
      const char *url = next_urls[i];

      this->get_track_url_at(current_index + i + 1, result);

      if (strcmp(url, result) != 0) {

        std::string str = std::to_string(current_index + i + 1);
        const char *cstr = str.c_str();

        if (strcmp(result, "") != 0) {
          const char *cmd[] = {"playlist-remove", cstr, NULL};
          mpv_command(mpv, cmd);
        }

        const char *cmd[] = {"loadfile", url, "insert-at", cstr, NULL};
        mpv_command(mpv, cmd);
      }
    }

    int playlist_length = this->get_playlist_length();

    int from = next_urls.size() + current_index + 1;
    int to = playlist_length;

    for (size_t i = to; i > from; i--) {
      std::string str = std::to_string(i - 1);
      const char *cstr = str.c_str();

      const char *cmd[] = {"playlist-remove", cstr, NULL};
      mpv_command(mpv, cmd);
    }

    dont_send_audio_changed.store(false);
  }

  int64_t get_current_track_pos() {
    int64_t pos = -1;
    mpv_get_property(mpv, "playlist-playing-pos", MPV_FORMAT_INT64, &pos);
    return pos;
  }

  int64_t get_playlist_length() {
    int64_t pos = -1;
    mpv_get_property(mpv, "playlist-count", MPV_FORMAT_INT64, &pos);
    return pos;
  }

  int64_t get_current_position() {
    double position = 0.0;
    mpv_get_property(mpv, "audio-pts", MPV_FORMAT_DOUBLE, &position);
    int64_t finalPos = (int64_t)(position * 1000);

    if (finalPos != 0) {
      return finalPos;
    }

    mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &position);
    return (int64_t)(position * 1000);
  }

  int64_t get_current_buffered_position() {
    double buffered_position = 0.0;
    mpv_get_property(mpv, "demuxer-cache-time", MPV_FORMAT_DOUBLE,
                     &buffered_position);
    return (int64_t)(buffered_position * 1000);
  }

  bool get_current_playing() {
    int64_t is_paused = 0;
    mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &is_paused);
    return !is_paused;
  }

  bool has_eof_reached() {
    int64_t is_eof = 0;
    mpv_get_property(mpv, "eof-reached", MPV_FORMAT_FLAG, &is_eof);
    return is_eof;
  }

  void set_loop_mode(MelodinkLoopMode loop) {
    if (loop == MELODINK_LOOP_MODE_ONE) {
      mpv_set_property_string(mpv, "loop", "inf");
      mpv_set_property_string(mpv, "loop-playlist", "no");
      return;
    }
    if (loop == MELODINK_LOOP_MODE_ALL) {
      mpv_set_property_string(mpv, "loop", "no");
      mpv_set_property_string(mpv, "loop-playlist", "inf");
      return;
    }
    mpv_set_property_string(mpv, "loop", "no");
    mpv_set_property_string(mpv, "loop-playlist", "no");
  }

  MelodinkLoopMode get_current_loop_mode() {
    char *loop_mode;
    loop_mode = mpv_get_property_string(mpv, "loop");

    char *loop_playlist_mode;
    loop_playlist_mode = mpv_get_property_string(mpv, "loop-playlist");

    if (strcmp(loop_mode, "inf") == 0) {
      mpv_free(loop_mode);
      mpv_free(loop_playlist_mode);

      return MELODINK_LOOP_MODE_ONE;
    }

    if (strcmp(loop_playlist_mode, "inf") == 0) {
      mpv_free(loop_mode);
      mpv_free(loop_playlist_mode);

      return MELODINK_LOOP_MODE_ALL;
    }

    mpv_free(loop_mode);
    mpv_free(loop_playlist_mode);

    return MELODINK_LOOP_MODE_NONE;
  }

  MelodinkProcessingState get_current_player_state() { return state; }

  void set_auth_token(const char *auth_token) {
    char auth_header[1024];
    snprintf(auth_header, sizeof(auth_header), "Cookie: %s", auth_token);

    char headers[2048];
    snprintf(headers, sizeof(headers), "%s\nUser-Agent: Melodink-MPV",
             auth_header);

    mpv_set_option_string(mpv, "http-header-fields", headers);
  }
};
