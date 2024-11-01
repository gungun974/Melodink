#pragma once

#include <string>

// #include "dart-dl/dart_api_dl.h"

// static Dart_Port_DL dart_port = 0;

void (*dart_send_event_audio_changed)(int64_t);

void send_event_audio_changed(int64_t value) {
  if (dart_send_event_audio_changed != NULL) {
    dart_send_event_audio_changed(value);
  }

  // if (!dart_port)
  //   return;
  // Dart_CObject msg;
  // msg.type = Dart_CObject_kString;
  // msg.value.as_string = "hoi";
  // // The function is thread-safe; you can call it anywhere on your C++ code
  // Dart_PostCObject_DL(dart_port, &msg);

  // std::thread threadSend([value]() {
  //   JNIEnv *env;
  //
  //   if (javaVM->AttachCurrentThread(&env, nullptr) != 0) {
  //     return;
  //   }
  //
  //   jclass kotlinClass = env->GetObjectClass(kotlinObjectRef);
  //   if (kotlinClass == nullptr) {
  //     javaVM->DetachCurrentThread();
  //     return;
  //   }
  //
  //   jmethodID ndkSendEventAudioChanged =
  //       env->GetMethodID(kotlinClass, "sendEventAudioChanged", "(J)V");
  //   if (ndkSendEventAudioChanged == nullptr) {
  //     javaVM->DetachCurrentThread();
  //     return;
  //   }
  //
  //   env->CallVoidMethod(kotlinObjectRef, ndkSendEventAudioChanged,
  //                       static_cast<jlong>(value));
  //
  //   env->DeleteLocalRef(kotlinClass);
  //
  //   javaVM->DetachCurrentThread();
  // });
  // threadSend.detach();
}

void (*dart_send_event_update_state)(int64_t);

void send_event_update_state(int64_t value) {
  if (dart_send_event_update_state != NULL) {
    dart_send_event_update_state(value);
  }
  // std::thread threadSend([value]() {
  //   JNIEnv *env;
  //
  //   if (javaVM->AttachCurrentThread(&env, nullptr) != 0) {
  //     return;
  //   }
  //
  //   jclass kotlinClass = env->GetObjectClass(kotlinObjectRef);
  //   if (kotlinClass == nullptr) {
  //     javaVM->DetachCurrentThread();
  //     return;
  //   }
  //
  //   jmethodID ndkSendEventUpdateState =
  //       env->GetMethodID(kotlinClass, "sendEventUpdateState", "(J)V");
  //   if (ndkSendEventUpdateState == nullptr) {
  //     javaVM->DetachCurrentThread();
  //     return;
  //   }
  //
  //   env->CallVoidMethod(kotlinObjectRef, ndkSendEventUpdateState,
  //                       static_cast<jlong>(value));
  //
  //   env->DeleteLocalRef(kotlinClass);
  //
  //   javaVM->DetachCurrentThread();
  // });
  // threadSend.detach();
}
