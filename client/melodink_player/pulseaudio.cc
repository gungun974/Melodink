#pragma once

#include "miniaudio.h"
#include <pulse/pulseaudio.h>

ma_result (*ma_context_init__pulse)(ma_context *, const ma_context_config *,
                                    ma_backend_callbacks *);

std::mutex mi_pa_mainloop_iterate_mutex;

int mi_pa_mainloop_iterate(pa_mainloop *m, int block, int *retval) {
  mi_pa_mainloop_iterate_mutex.lock();
  int result = pa_mainloop_iterate(m, block, retval);
  mi_pa_mainloop_iterate_mutex.unlock();
  return result;
}

ma_result mi_result_from_pulse(int result) {
  if (result < 0) {
    return MA_ERROR;
  }

  switch (result) {
  case PA_OK:
    return MA_SUCCESS;
  case PA_ERR_ACCESS:
    return MA_ACCESS_DENIED;
  case PA_ERR_INVALID:
    return MA_INVALID_ARGS;
  case PA_ERR_NOENTITY:
    return MA_NO_DEVICE;
  default:
    return MA_ERROR;
  }
}

ma_result mi_wait_for_operation__pulse(ma_context *pContext, ma_ptr pMainLoop,
                                       pa_operation *pOP) {
  int resultPA;
  pa_operation_state_t state;

  assert(pContext != NULL);
  assert(pOP != NULL);

  for (;;) {
    state = pa_operation_get_state(pOP);
    if (state != PA_OPERATION_RUNNING) {
      break;
    }

    resultPA = mi_pa_mainloop_iterate((pa_mainloop *)(pMainLoop), 1, NULL);
    if (resultPA < 0) {
      return mi_result_from_pulse(resultPA);
    }
  }

  return MA_SUCCESS;
}

void mi_set_volume_callback__pulse(pa_context *c, int success, void *userdata) {
  bool *done = (bool *)userdata;

  *done = 1;
}

void mi_set_volume__pulse(ma_device *audio_device, double audio_volume) {
  pa_cvolume volume;
  pa_cvolume_set(&volume, 2, (pa_volume_t)(PA_VOLUME_NORM * audio_volume));

  pa_operation *pOP = NULL;
  bool done = false;

  uint32_t index =
      pa_stream_get_index((pa_stream *)(audio_device->pulse.pStreamPlayback));

  pOP = pa_context_set_sink_input_volume(
      (pa_context *)(audio_device->pulse.pPulseContext), index, &volume,
      mi_set_volume_callback__pulse, &done);

  if (!pOP) {
    return;
  }

  while (!done) {
    ma_device_state device_state = ma_device_get_state(audio_device);

    if (device_state == ma_device_state_stopped) {
      ma_device_stop(audio_device);
      mi_wait_for_operation__pulse(audio_device->pContext,
                                   audio_device->pulse.pMainLoop, pOP);
    }
  }

  pa_operation_unref(pOP);
}

typedef struct {
  double volume;
  int done;
} volume_query_t;

void mi_get_volume_callback__pulse(pa_context *c, const pa_sink_input_info *i,
                                   int eol, void *userdata) {
  if (eol) {
    return;
  }

  volume_query_t *query = (volume_query_t *)userdata;

  if (eol || !i) {
    query->done = 1;
    return;
  }

  if (i->volume.channels > 0) {
    query->volume = pa_cvolume_avg(&i->volume) / (double)PA_VOLUME_NORM;
  } else {
    query->volume = -1.0;
  }

  query->done = 1;
}

double mi_get_volume__pulse(ma_device *audio_device) {
  pa_operation *pOP = NULL;
  volume_query_t query = {.volume = -1.0, .done = 0};

  uint32_t index =
      pa_stream_get_index((pa_stream *)(audio_device->pulse.pStreamPlayback));

  pOP = pa_context_get_sink_input_info(
      (pa_context *)(audio_device->pulse.pPulseContext), index,
      mi_get_volume_callback__pulse, &query);

  if (!pOP) {
    return -1.0;
  }

  while (!query.done) {
    ma_device_state device_state = ma_device_get_state(audio_device);

    if (device_state == ma_device_state_stopped) {
      ma_device_stop(audio_device);
      mi_wait_for_operation__pulse(audio_device->pContext,
                                   audio_device->pulse.pMainLoop, pOP);
    }
  }

  pa_operation_unref(pOP);
  return query.volume;
}
