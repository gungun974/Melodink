#include <string>
#include <vector>

#include <atomic>
#include <thread>

#include <mpv/client.h>

struct HostPlayerApiInfoAudioChangedMessageData {
  PigeonMelodinkMelodinkHostPlayerApiInfo *flutter_api;
  int64_t value;
};

struct HostPlayerApiInfoUpdateStateMessageData {
  PigeonMelodinkMelodinkHostPlayerApiInfo *flutter_api;
  PigeonMelodinkMelodinkHostPlayerProcessingState value;
};

gboolean
send_event_melodink_host_player_api_info_audio_changed(gpointer user_data) {
  HostPlayerApiInfoAudioChangedMessageData *message_data =
      static_cast<HostPlayerApiInfoAudioChangedMessageData *>(user_data);

  pigeon_melodink_melodink_host_player_api_info_audio_changed(
      message_data->flutter_api, message_data->value, nullptr, NULL, NULL);

  delete message_data;

  return FALSE;
}

gboolean
send_event_melodink_host_player_api_info_update_state(gpointer user_data) {
  HostPlayerApiInfoUpdateStateMessageData *message_data =
      static_cast<HostPlayerApiInfoUpdateStateMessageData *>(user_data);

  pigeon_melodink_melodink_host_player_api_info_update_state(
      message_data->flutter_api, message_data->value, nullptr, NULL, NULL);

  delete message_data;

  return FALSE;
}

class AudioPlayer {
private:
  mpv_handle *mpv;

  std::thread event_thread;
  std::atomic<bool> stop_event_thread;
  std::atomic<bool> dont_send_audio_changed;

  PigeonMelodinkMelodinkHostPlayerApiInfo *flutter_api;

  PigeonMelodinkMelodinkHostPlayerProcessingState state =
      PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_IDLE;

  void set_player_state(PigeonMelodinkMelodinkHostPlayerProcessingState state) {
    this->state = state;

    HostPlayerApiInfoUpdateStateMessageData *message_data =
        new HostPlayerApiInfoUpdateStateMessageData{flutter_api, state};

    g_idle_add(send_event_melodink_host_player_api_info_update_state,
               message_data);
  }

  void event_loop() {
    while (!stop_event_thread.load()) {
      mpv_event *event = mpv_wait_event(mpv, 1000);
      if (event->event_id == MPV_EVENT_SHUTDOWN) {
        set_player_state(
            PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_IDLE);
        break;
      }

      if (event->event_id == MPV_EVENT_PLAYBACK_RESTART) {
        set_player_state(
            PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_READY);
      }

      if (event->event_id == MPV_EVENT_SEEK) {
        set_player_state(
            PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_READY);
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

          HostPlayerApiInfoAudioChangedMessageData *message_data =
              new HostPlayerApiInfoAudioChangedMessageData{flutter_api, pos};

          g_idle_add(send_event_melodink_host_player_api_info_audio_changed,
                     message_data);
        }
        if (strcmp(prop->name, "pause") == 0) {
          int paused = *(int *)prop->data;

          if (paused) {
            continue;
          }

          set_player_state(
              PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_READY);
        }

        if (strcmp(prop->name, "idle-active") == 0) {
          int idle = *(int *)prop->data;
          if (idle) {
            set_player_state(
                PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_IDLE);
          }
        }

        if (strcmp(prop->name, "eof-reached") == 0) {
          int eof = has_eof_reached();
          if (eof) {
            set_player_state(
                PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_IDLE);
          }
        }
      }
    }
  }

public:
  AudioPlayer(PigeonMelodinkMelodinkHostPlayerApiInfo *flutter_api) {
    this->flutter_api = flutter_api;

    setlocale(LC_ALL, "C");

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

  void seek(int position_ms) {
    set_player_state(
        PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_BUFFERING);

    double position_seconds = position_ms / 1000.0;
    mpv_set_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &position_seconds);
  }

  void get_track_url_at(int index, char *result) {
    char target[255];

    sprintf(target, "playlist/%d/filename", index);

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

    g_print("---------------\n");
    for (int i = 0; i < this->get_playlist_length(); i++) {
      this->get_track_url_at(i, result);
      g_print("%d : %s\n", i, result);
    }
  }

  void set_audios(std::vector<const char *> previous_urls,
                  std::vector<const char *> next_urls) {
    char result[255];

    set_player_state(
        PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_IDLE);

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

    set_player_state(
        PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_READY);

    dont_send_audio_changed.store(false);
  }

  int get_current_track_pos() {
    int pos = -1;
    mpv_get_property(mpv, "playlist-playing-pos", MPV_FORMAT_INT64, &pos);
    return pos;
  }

  int get_playlist_length() {
    int pos = -1;
    mpv_get_property(mpv, "playlist-count", MPV_FORMAT_INT64, &pos);
    return pos;
  }

  int get_current_position() {
    double position = 0.0;
    mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &position);
    return (int)(position * 1000);
  }

  int get_current_buffered_position() {
    double buffered_position = 0.0;
    mpv_get_property(mpv, "demuxer-cache-time", MPV_FORMAT_DOUBLE,
                     &buffered_position);
    return (int)(buffered_position * 1000);
  }

  bool get_current_playing() {
    int is_paused = 0;
    mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &is_paused);
    return !is_paused;
  }

  bool has_eof_reached() {
    int is_eof = 0;
    mpv_get_property(mpv, "eof-reached", MPV_FORMAT_FLAG, &is_eof);
    return is_eof;
  }

  void set_loop_mode(PigeonMelodinkMelodinkHostPlayerLoopMode loop) {
    if (loop == PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_ONE) {
      mpv_set_property_string(mpv, "loop", "inf");
      mpv_set_property_string(mpv, "loop-playlist", "no");
      return;
    }
    if (loop == PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_ALL) {
      mpv_set_property_string(mpv, "loop", "no");
      mpv_set_property_string(mpv, "loop-playlist", "inf");
      return;
    }
    mpv_set_property_string(mpv, "loop", "no");
    mpv_set_property_string(mpv, "loop-playlist", "no");
  }

  PigeonMelodinkMelodinkHostPlayerLoopMode get_current_loop_mode() {
    char *loop_mode;
    loop_mode = mpv_get_property_string(mpv, "loop");

    char *loop_playlist_mode;
    loop_playlist_mode = mpv_get_property_string(mpv, "loop-playlist");

    if (strcmp(loop_mode, "inf") == 0) {
      mpv_free(loop_mode);
      mpv_free(loop_playlist_mode);

      return PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_ONE;
    }

    if (strcmp(loop_playlist_mode, "inf") == 0) {
      mpv_free(loop_mode);
      mpv_free(loop_playlist_mode);

      return PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_ALL;
    }

    mpv_free(loop_mode);
    mpv_free(loop_playlist_mode);

    return PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_NONE;
  }

  PigeonMelodinkMelodinkHostPlayerProcessingState get_current_player_state() {
    return state;
  }

  void set_auth_token(const char *auth_token) {
    char auth_header[1024];
    snprintf(auth_header, sizeof(auth_header), "Cookie: %s", auth_token);

    char headers[2048];
    snprintf(headers, sizeof(headers), "%s\nUser-Agent: Melodink-MPV",
             auth_header);

    mpv_set_option_string(mpv, "http-header-fields", headers);
  }
};
