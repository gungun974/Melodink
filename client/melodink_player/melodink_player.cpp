#include <stdio.h>

#include "player.cc"

MelodinkPlayer *player = nullptr;

extern "C" void mi_player_init() {
  if (player == nullptr) {
    player = new MelodinkPlayer();
  }

  return;
}

extern "C" void
mi_register_event_audio_changed_callback(void (*callback)(int64_t)) {
  dart_send_event_audio_changed = callback;
}

extern "C" void
mi_register_event_update_state_callback(void (*callback)(int64_t)) {
  dart_send_event_update_state = callback;
}

extern "C" void mi_player_play() {
  player->Play();

  return;
}

extern "C" void mi_player_pause() {
  player->Pause();

  return;
}

extern "C" void mi_player_seek(int64_t position_ms) {
  player->Seek(position_ms);

  return;
}

extern "C" void mi_player_skip_to_previous() {
  player->Prev();

  return;
}

extern "C" void mi_player_skip_to_next() {
  player->Next();

  return;
}

extern "C" void mi_player_set_audios(const char **previous_urls,
                                     const char **next_urls) {
  std::vector<const char *> vector_previous_urls;
  std::vector<const char *> vector_next_urls;

  for (const char **ptr = previous_urls; *ptr != nullptr; ptr++) {
    vector_previous_urls.push_back(*ptr);
  }

  for (const char **ptr = next_urls; *ptr != nullptr; ptr++) {
    vector_next_urls.push_back(*ptr);
  }

  player->SetAudios(vector_previous_urls, vector_next_urls);

  return;
}

extern "C" void mi_player_set_loop_mode(MelodinkLoopMode loop) {
  player->SetLoopMode(loop);

  return;
}

extern "C" void mi_player_set_auth_token(const char *auth_token) {
  player->SetAuthToken(auth_token);

  return;
}

extern "C" bool mi_player_get_current_playing() {
  return player->GetCurrentPlaying();
}

extern "C" int64_t mi_player_get_current_track_pos() {
  return player->GetCurrentTrackPos();
}

extern "C" int64_t mi_player_get_current_position() {
  return player->GetCurrentPosition();
}

extern "C" int64_t mi_player_get_current_buffered_position() {
  return player->GetCurrentBufferedPosition();
}

extern "C" int64_t mi_player_get_current_player_state() {
  return player->GetCurrentPlayerState();
}

extern "C" int64_t mi_player_get_current_loop_mode() {
  return player->GetCurrentLoopMode();
}

extern "C" void mi_player_set_volume(double volume) {
  player->SetVolume(volume);
}

extern "C" double mi_player_get_volume() { return player->GetVolume(); }
