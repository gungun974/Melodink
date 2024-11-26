#include <stdio.h>

#include "player.cc"
#include "sendevent.h"

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
  fprintf(stderr, "START play\n");
  player->Play();
  fprintf(stderr, "END play\n");

  return;
}

extern "C" void mi_player_pause() {
  fprintf(stderr, "START pause\n");
  player->Pause();
  fprintf(stderr, "END pause\n");

  return;
}

extern "C" void mi_player_seek(int64_t position_ms) {
  fprintf(stderr, "START seek\n");
  player->Seek(position_ms);
  fprintf(stderr, "END seek\n");

  return;
}

extern "C" void mi_player_skip_to_previous() {
  fprintf(stderr, "START prev\n");
  player->Prev();
  fprintf(stderr, "END prev\n");

  return;
}

extern "C" void mi_player_skip_to_next() {
  fprintf(stderr, "START next\n");
  player->Next();
  fprintf(stderr, "END next\n");

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

  fprintf(stderr, "START SetAudios\n");
  player->SetAudios(vector_previous_urls, vector_next_urls);
  fprintf(stderr, "END SetAudios\n");

  return;
}

extern "C" void mi_player_set_loop_mode(MelodinkLoopMode loop) {
  fprintf(stderr, "START SetLoopMode\n");
  player->SetLoopMode(loop);
  fprintf(stderr, "END SetLoopMode\n");

  return;
}

extern "C" void mi_player_set_auth_token(const char *auth_token) {
  player->SetAuthToken(auth_token);

  return;
}

extern "C" bool mi_player_get_current_playing() {
  fprintf(stderr, "START GetCurrentPlaying\n");
  auto val = player->GetCurrentPlaying();
  fprintf(stderr, "END GetCurrentPlaying\n");
  return val;
}

extern "C" int64_t mi_player_get_current_track_pos() {
  fprintf(stderr, "START GetCurrentTrackPos\n");
  auto val = player->GetCurrentTrackPos();
  fprintf(stderr, "END GetCurrentTrackPos\n");
  return val;
}

extern "C" int64_t mi_player_get_current_position() {
  fprintf(stderr, "START GetCurrentPosition\n");
  auto val = player->GetCurrentPosition();
  fprintf(stderr, "END GetCurrentPosition\n");
  return val;
}

extern "C" int64_t mi_player_get_current_buffered_position() {
  return player->GetCurrentBufferedPosition();
}

extern "C" int64_t mi_player_get_current_player_state() {
  fprintf(stderr, "START GetCurrentPlayerState\n");
  auto val = player->GetCurrentPlayerState();
  fprintf(stderr, "END GetCurrentPlayerState\n");
  return val;
}

extern "C" int64_t mi_player_get_current_loop_mode() {
  fprintf(stderr, "START GetCurrentLoopMode\n");
  auto val = player->GetCurrentLoopMode();
  fprintf(stderr, "END GetCurrentLoopMode\n");
  return val;
}

extern "C" void mi_player_set_volume(double volume) {
  player->SetVolume(volume);
}

extern "C" double mi_player_get_volume() { return player->GetVolume(); }
