#include <stdio.h>

#include "player.cc"

AudioPlayer *player = nullptr;

extern "C" void init() {
  if (player == nullptr) {
    player = new AudioPlayer();
  }

  return;
}

extern "C" void
register_event_audio_changed_callback(void (*callback)(int64_t)) {
  dart_send_event_audio_changed = callback;
}

extern "C" void
register_event_update_state_callback(void (*callback)(int64_t)) {
  dart_send_event_update_state = callback;
}

extern "C" void play() {
  player->play();

  return;
}

extern "C" void pause() {
  player->pause();

  return;
}

extern "C" void seek(int64_t position_ms) {
  player->seek(position_ms);

  return;
}

extern "C" void skip_to_previous() {
  player->prev();

  return;
}

extern "C" void skip_to_next() {
  player->next();

  return;
}

extern "C" void set_audios(const char **previous_urls, const char **next_urls) {
  std::vector<const char *> vector_previous_urls;
  std::vector<const char *> vector_next_urls;

  // Remplir vector_previous_urls
  for (const char **ptr = previous_urls; *ptr != nullptr; ptr++) {
    vector_previous_urls.push_back(*ptr);
  }

  // Remplir vector_next_urls
  for (const char **ptr = next_urls; *ptr != nullptr; ptr++) {
    vector_next_urls.push_back(*ptr);
  }

  player->set_audios(vector_previous_urls, vector_next_urls);

  return;
}

extern "C" void set_loop_mode(MelodinkLoopMode loop) {
  player->set_loop_mode(loop);

  return;
}

extern "C" void set_auth_token(const char *auth_token) {
  player->set_auth_token(auth_token);

  return;
}

extern "C" bool get_current_playing() { return player->get_current_playing(); }

extern "C" int64_t get_current_track_pos() {
  return player->get_current_track_pos();
}

extern "C" int64_t get_current_position() {
  return player->get_current_position();
}

extern "C" int64_t get_current_buffered_position() {
  return player->get_current_buffered_position();
}

extern "C" int64_t get_current_player_state() {
  return player->get_current_player_state();
}

extern "C" int64_t get_current_loop_mode() {
  return player->get_current_loop_mode();
}

extern "C" void set_volume(double volume) { player->set_volume(volume); }

extern "C" double get_volume() { return player->get_volume(); }
