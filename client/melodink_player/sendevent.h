#ifndef SENDEVENT_H
#define SENDEVENT_H

#include <string>

extern void (*dart_send_event_audio_changed)(int64_t);
extern void (*dart_send_event_update_state)(int64_t);

void send_event_audio_changed(int64_t value);
void send_event_update_state(int64_t value);

#endif
