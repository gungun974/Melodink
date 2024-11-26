#ifndef NOM_UNIQUE_DU_FICHIER_H
#define NOM_UNIQUE_DU_FICHIER_H

#include <string>

void (*dart_send_event_audio_changed)(int64_t);

void send_event_audio_changed(int64_t value) {
  if (dart_send_event_audio_changed != NULL) {
    dart_send_event_audio_changed(value);
  }
}

void (*dart_send_event_update_state)(int64_t);

void send_event_update_state(int64_t value) {
  if (dart_send_event_update_state != NULL) {
    dart_send_event_update_state(value);
  }
}

#endif // NOM_UNIQUE_DU_FICHIER_H
