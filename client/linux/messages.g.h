// Autogenerated from Pigeon (v21.1.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#ifndef PIGEON_MESSAGES_G_H_
#define PIGEON_MESSAGES_G_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

/**
 * PigeonMelodinkMelodinkHostPlayerProcessingState:
 * PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_IDLE:
 * There hasn't been any resource loaded yet.
 * PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_LOADING:
 * Resource is being loaded.
 * PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_BUFFERING:
 * Resource is being buffered.
 * PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_READY:
 * Resource is buffered enough and available for playback.
 * PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_COMPLETED:
 * The end of resource was reached.
 *
 */
typedef enum {
  PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_IDLE = 0,
  PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_LOADING = 1,
  PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_BUFFERING = 2,
  PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_READY = 3,
  PIGEON_MELODINK_MELODINK_HOST_PLAYER_PROCESSING_STATE_COMPLETED = 4
} PigeonMelodinkMelodinkHostPlayerProcessingState;

/**
 * PigeonMelodinkMelodinkHostPlayerLoopMode:
 * PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_NONE:
 * The current media item or queue will not repeat.
 * PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_ONE:
 * The current media item will repeat.
 * PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_ALL:
 * Playback will continue looping through all media items in the current list.
 *
 */
typedef enum {
  PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_NONE = 0,
  PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_ONE = 1,
  PIGEON_MELODINK_MELODINK_HOST_PLAYER_LOOP_MODE_ALL = 2
} PigeonMelodinkMelodinkHostPlayerLoopMode;

/**
 * PigeonMelodinkPlayerStatus:
 *
 */

G_DECLARE_FINAL_TYPE(PigeonMelodinkPlayerStatus, pigeon_melodink_player_status, PIGEON_MELODINK, PLAYER_STATUS, GObject)

/**
 * pigeon_melodink_player_status_new:
 * playing: field in this object.
 * pos: field in this object.
 * position_ms: field in this object.
 * buffered_position_ms: field in this object.
 * state: field in this object.
 * loop: field in this object.
 *
 * Creates a new #PlayerStatus object.
 *
 * Returns: a new #PigeonMelodinkPlayerStatus
 */
PigeonMelodinkPlayerStatus* pigeon_melodink_player_status_new(gboolean playing, int64_t pos, int64_t position_ms, int64_t buffered_position_ms, PigeonMelodinkMelodinkHostPlayerProcessingState state, PigeonMelodinkMelodinkHostPlayerLoopMode loop);

/**
 * pigeon_melodink_player_status_get_playing
 * @object: a #PigeonMelodinkPlayerStatus.
 *
 * Gets the value of the playing field of @object.
 *
 * Returns: the field value.
 */
gboolean pigeon_melodink_player_status_get_playing(PigeonMelodinkPlayerStatus* object);

/**
 * pigeon_melodink_player_status_get_pos
 * @object: a #PigeonMelodinkPlayerStatus.
 *
 * Gets the value of the pos field of @object.
 *
 * Returns: the field value.
 */
int64_t pigeon_melodink_player_status_get_pos(PigeonMelodinkPlayerStatus* object);

/**
 * pigeon_melodink_player_status_get_position_ms
 * @object: a #PigeonMelodinkPlayerStatus.
 *
 * Gets the value of the positionMs field of @object.
 *
 * Returns: the field value.
 */
int64_t pigeon_melodink_player_status_get_position_ms(PigeonMelodinkPlayerStatus* object);

/**
 * pigeon_melodink_player_status_get_buffered_position_ms
 * @object: a #PigeonMelodinkPlayerStatus.
 *
 * Gets the value of the bufferedPositionMs field of @object.
 *
 * Returns: the field value.
 */
int64_t pigeon_melodink_player_status_get_buffered_position_ms(PigeonMelodinkPlayerStatus* object);

/**
 * pigeon_melodink_player_status_get_state
 * @object: a #PigeonMelodinkPlayerStatus.
 *
 * Gets the value of the state field of @object.
 *
 * Returns: the field value.
 */
PigeonMelodinkMelodinkHostPlayerProcessingState pigeon_melodink_player_status_get_state(PigeonMelodinkPlayerStatus* object);

/**
 * pigeon_melodink_player_status_get_loop
 * @object: a #PigeonMelodinkPlayerStatus.
 *
 * Gets the value of the loop field of @object.
 *
 * Returns: the field value.
 */
PigeonMelodinkMelodinkHostPlayerLoopMode pigeon_melodink_player_status_get_loop(PigeonMelodinkPlayerStatus* object);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiPlayResponse, pigeon_melodink_melodink_host_player_api_play_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_PLAY_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_play_response_new:
 *
 * Creates a new response to MelodinkHostPlayerApi.play.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiPlayResponse
 */
PigeonMelodinkMelodinkHostPlayerApiPlayResponse* pigeon_melodink_melodink_host_player_api_play_response_new();

/**
 * pigeon_melodink_melodink_host_player_api_play_response_new_error:
 * @code: error code.
 * @message: error message.
 * @details: (allow-none): error details or %NULL.
 *
 * Creates a new error response to MelodinkHostPlayerApi.play.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiPlayResponse
 */
PigeonMelodinkMelodinkHostPlayerApiPlayResponse* pigeon_melodink_melodink_host_player_api_play_response_new_error(const gchar* code, const gchar* message, FlValue* details);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiPauseResponse, pigeon_melodink_melodink_host_player_api_pause_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_PAUSE_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_pause_response_new:
 *
 * Creates a new response to MelodinkHostPlayerApi.pause.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiPauseResponse
 */
PigeonMelodinkMelodinkHostPlayerApiPauseResponse* pigeon_melodink_melodink_host_player_api_pause_response_new();

/**
 * pigeon_melodink_melodink_host_player_api_pause_response_new_error:
 * @code: error code.
 * @message: error message.
 * @details: (allow-none): error details or %NULL.
 *
 * Creates a new error response to MelodinkHostPlayerApi.pause.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiPauseResponse
 */
PigeonMelodinkMelodinkHostPlayerApiPauseResponse* pigeon_melodink_melodink_host_player_api_pause_response_new_error(const gchar* code, const gchar* message, FlValue* details);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiSeekResponse, pigeon_melodink_melodink_host_player_api_seek_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_SEEK_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_seek_response_new:
 *
 * Creates a new response to MelodinkHostPlayerApi.seek.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSeekResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSeekResponse* pigeon_melodink_melodink_host_player_api_seek_response_new();

/**
 * pigeon_melodink_melodink_host_player_api_seek_response_new_error:
 * @code: error code.
 * @message: error message.
 * @details: (allow-none): error details or %NULL.
 *
 * Creates a new error response to MelodinkHostPlayerApi.seek.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSeekResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSeekResponse* pigeon_melodink_melodink_host_player_api_seek_response_new_error(const gchar* code, const gchar* message, FlValue* details);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiSkipToNextResponse, pigeon_melodink_melodink_host_player_api_skip_to_next_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_SKIP_TO_NEXT_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_skip_to_next_response_new:
 *
 * Creates a new response to MelodinkHostPlayerApi.skipToNext.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSkipToNextResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSkipToNextResponse* pigeon_melodink_melodink_host_player_api_skip_to_next_response_new();

/**
 * pigeon_melodink_melodink_host_player_api_skip_to_next_response_new_error:
 * @code: error code.
 * @message: error message.
 * @details: (allow-none): error details or %NULL.
 *
 * Creates a new error response to MelodinkHostPlayerApi.skipToNext.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSkipToNextResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSkipToNextResponse* pigeon_melodink_melodink_host_player_api_skip_to_next_response_new_error(const gchar* code, const gchar* message, FlValue* details);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiSkipToPreviousResponse, pigeon_melodink_melodink_host_player_api_skip_to_previous_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_SKIP_TO_PREVIOUS_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_skip_to_previous_response_new:
 *
 * Creates a new response to MelodinkHostPlayerApi.skipToPrevious.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSkipToPreviousResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSkipToPreviousResponse* pigeon_melodink_melodink_host_player_api_skip_to_previous_response_new();

/**
 * pigeon_melodink_melodink_host_player_api_skip_to_previous_response_new_error:
 * @code: error code.
 * @message: error message.
 * @details: (allow-none): error details or %NULL.
 *
 * Creates a new error response to MelodinkHostPlayerApi.skipToPrevious.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSkipToPreviousResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSkipToPreviousResponse* pigeon_melodink_melodink_host_player_api_skip_to_previous_response_new_error(const gchar* code, const gchar* message, FlValue* details);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiSetAudiosResponse, pigeon_melodink_melodink_host_player_api_set_audios_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_SET_AUDIOS_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_set_audios_response_new:
 *
 * Creates a new response to MelodinkHostPlayerApi.setAudios.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSetAudiosResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSetAudiosResponse* pigeon_melodink_melodink_host_player_api_set_audios_response_new();

/**
 * pigeon_melodink_melodink_host_player_api_set_audios_response_new_error:
 * @code: error code.
 * @message: error message.
 * @details: (allow-none): error details or %NULL.
 *
 * Creates a new error response to MelodinkHostPlayerApi.setAudios.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSetAudiosResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSetAudiosResponse* pigeon_melodink_melodink_host_player_api_set_audios_response_new_error(const gchar* code, const gchar* message, FlValue* details);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiSetLoopModeResponse, pigeon_melodink_melodink_host_player_api_set_loop_mode_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_SET_LOOP_MODE_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_set_loop_mode_response_new:
 *
 * Creates a new response to MelodinkHostPlayerApi.setLoopMode.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSetLoopModeResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSetLoopModeResponse* pigeon_melodink_melodink_host_player_api_set_loop_mode_response_new();

/**
 * pigeon_melodink_melodink_host_player_api_set_loop_mode_response_new_error:
 * @code: error code.
 * @message: error message.
 * @details: (allow-none): error details or %NULL.
 *
 * Creates a new error response to MelodinkHostPlayerApi.setLoopMode.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiSetLoopModeResponse
 */
PigeonMelodinkMelodinkHostPlayerApiSetLoopModeResponse* pigeon_melodink_melodink_host_player_api_set_loop_mode_response_new_error(const gchar* code, const gchar* message, FlValue* details);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiFetchStatusResponse, pigeon_melodink_melodink_host_player_api_fetch_status_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_FETCH_STATUS_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_fetch_status_response_new:
 *
 * Creates a new response to MelodinkHostPlayerApi.fetchStatus.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiFetchStatusResponse
 */
PigeonMelodinkMelodinkHostPlayerApiFetchStatusResponse* pigeon_melodink_melodink_host_player_api_fetch_status_response_new(PigeonMelodinkPlayerStatus* return_value);

/**
 * pigeon_melodink_melodink_host_player_api_fetch_status_response_new_error:
 * @code: error code.
 * @message: error message.
 * @details: (allow-none): error details or %NULL.
 *
 * Creates a new error response to MelodinkHostPlayerApi.fetchStatus.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiFetchStatusResponse
 */
PigeonMelodinkMelodinkHostPlayerApiFetchStatusResponse* pigeon_melodink_melodink_host_player_api_fetch_status_response_new_error(const gchar* code, const gchar* message, FlValue* details);

/**
 * PigeonMelodinkMelodinkHostPlayerApiVTable:
 *
 * Table of functions exposed by MelodinkHostPlayerApi to be implemented by the API provider.
 */
typedef struct {
  PigeonMelodinkMelodinkHostPlayerApiPlayResponse* (*play)(gpointer user_data);
  PigeonMelodinkMelodinkHostPlayerApiPauseResponse* (*pause)(gpointer user_data);
  PigeonMelodinkMelodinkHostPlayerApiSeekResponse* (*seek)(int64_t position_ms, gpointer user_data);
  PigeonMelodinkMelodinkHostPlayerApiSkipToNextResponse* (*skip_to_next)(gpointer user_data);
  PigeonMelodinkMelodinkHostPlayerApiSkipToPreviousResponse* (*skip_to_previous)(gpointer user_data);
  PigeonMelodinkMelodinkHostPlayerApiSetAudiosResponse* (*set_audios)(FlValue* previous_urls, FlValue* next_urls, gpointer user_data);
  PigeonMelodinkMelodinkHostPlayerApiSetLoopModeResponse* (*set_loop_mode)(PigeonMelodinkMelodinkHostPlayerLoopMode loop, gpointer user_data);
  PigeonMelodinkMelodinkHostPlayerApiFetchStatusResponse* (*fetch_status)(gpointer user_data);
} PigeonMelodinkMelodinkHostPlayerApiVTable;

/**
 * pigeon_melodink_melodink_host_player_api_set_method_handlers:
 *
 * @messenger: an #FlBinaryMessenger.
 * @suffix: (allow-none): a suffix to add to the API or %NULL for none.
 * @vtable: implementations of the methods in this API.
 * @user_data: (closure): user data to pass to the functions in @vtable.
 * @user_data_free_func: (allow-none): a function which gets called to free @user_data, or %NULL.
 *
 * Connects the method handlers in the MelodinkHostPlayerApi API.
 */
void pigeon_melodink_melodink_host_player_api_set_method_handlers(FlBinaryMessenger* messenger, const gchar* suffix, const PigeonMelodinkMelodinkHostPlayerApiVTable* vtable, gpointer user_data, GDestroyNotify user_data_free_func);

/**
 * pigeon_melodink_melodink_host_player_api_clear_method_handlers:
 *
 * @messenger: an #FlBinaryMessenger.
 * @suffix: (allow-none): a suffix to add to the API or %NULL for none.
 *
 * Clears the method handlers in the MelodinkHostPlayerApi API.
 */
void pigeon_melodink_melodink_host_player_api_clear_method_handlers(FlBinaryMessenger* messenger, const gchar* suffix);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse, pigeon_melodink_melodink_host_player_api_info_audio_changed_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_INFO_AUDIO_CHANGED_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_info_audio_changed_response_is_error:
 * @response: a #PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse.
 *
 * Checks if a response to MelodinkHostPlayerApiInfo.audioChanged is an error.
 *
 * Returns: a %TRUE if this response is an error.
 */
gboolean pigeon_melodink_melodink_host_player_api_info_audio_changed_response_is_error(PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse* response);

/**
 * pigeon_melodink_melodink_host_player_api_info_audio_changed_response_get_error_code:
 * @response: a #PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse.
 *
 * Get the error code for this response.
 *
 * Returns: an error code or %NULL if not an error.
 */
const gchar* pigeon_melodink_melodink_host_player_api_info_audio_changed_response_get_error_code(PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse* response);

/**
 * pigeon_melodink_melodink_host_player_api_info_audio_changed_response_get_error_message:
 * @response: a #PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse.
 *
 * Get the error message for this response.
 *
 * Returns: an error message.
 */
const gchar* pigeon_melodink_melodink_host_player_api_info_audio_changed_response_get_error_message(PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse* response);

/**
 * pigeon_melodink_melodink_host_player_api_info_audio_changed_response_get_error_details:
 * @response: a #PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse.
 *
 * Get the error details for this response.
 *
 * Returns: (allow-none): an error details or %NULL.
 */
FlValue* pigeon_melodink_melodink_host_player_api_info_audio_changed_response_get_error_details(PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse* response);

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse, pigeon_melodink_melodink_host_player_api_info_update_state_response, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_INFO_UPDATE_STATE_RESPONSE, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_info_update_state_response_is_error:
 * @response: a #PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse.
 *
 * Checks if a response to MelodinkHostPlayerApiInfo.updateState is an error.
 *
 * Returns: a %TRUE if this response is an error.
 */
gboolean pigeon_melodink_melodink_host_player_api_info_update_state_response_is_error(PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse* response);

/**
 * pigeon_melodink_melodink_host_player_api_info_update_state_response_get_error_code:
 * @response: a #PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse.
 *
 * Get the error code for this response.
 *
 * Returns: an error code or %NULL if not an error.
 */
const gchar* pigeon_melodink_melodink_host_player_api_info_update_state_response_get_error_code(PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse* response);

/**
 * pigeon_melodink_melodink_host_player_api_info_update_state_response_get_error_message:
 * @response: a #PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse.
 *
 * Get the error message for this response.
 *
 * Returns: an error message.
 */
const gchar* pigeon_melodink_melodink_host_player_api_info_update_state_response_get_error_message(PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse* response);

/**
 * pigeon_melodink_melodink_host_player_api_info_update_state_response_get_error_details:
 * @response: a #PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse.
 *
 * Get the error details for this response.
 *
 * Returns: (allow-none): an error details or %NULL.
 */
FlValue* pigeon_melodink_melodink_host_player_api_info_update_state_response_get_error_details(PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse* response);

/**
 * PigeonMelodinkMelodinkHostPlayerApiInfo:
 *
 */

G_DECLARE_FINAL_TYPE(PigeonMelodinkMelodinkHostPlayerApiInfo, pigeon_melodink_melodink_host_player_api_info, PIGEON_MELODINK, MELODINK_HOST_PLAYER_API_INFO, GObject)

/**
 * pigeon_melodink_melodink_host_player_api_info_new:
 * @messenger: an #FlBinaryMessenger.
 * @suffix: (allow-none): a suffix to add to the API or %NULL for none.
 *
 * Creates a new object to access the MelodinkHostPlayerApiInfo API.
 *
 * Returns: a new #PigeonMelodinkMelodinkHostPlayerApiInfo
 */
PigeonMelodinkMelodinkHostPlayerApiInfo* pigeon_melodink_melodink_host_player_api_info_new(FlBinaryMessenger* messenger, const gchar* suffix);

/**
 * pigeon_melodink_melodink_host_player_api_info_audio_changed:
 * @api: a #PigeonMelodinkMelodinkHostPlayerApiInfo.
 * @pos: parameter for this method.
 * @cancellable: (allow-none): a #GCancellable or %NULL.
 * @callback: (scope async): (allow-none): a #GAsyncReadyCallback to call when the call is complete or %NULL to ignore the response.
 * @user_data: (closure): user data to pass to @callback.
 *
 */
void pigeon_melodink_melodink_host_player_api_info_audio_changed(PigeonMelodinkMelodinkHostPlayerApiInfo* api, int64_t pos, GCancellable* cancellable, GAsyncReadyCallback callback, gpointer user_data);

/**
 * pigeon_melodink_melodink_host_player_api_info_audio_changed_finish:
 * @api: a #PigeonMelodinkMelodinkHostPlayerApiInfo.
 * @result: a #GAsyncResult.
 * @error: (allow-none): #GError location to store the error occurring, or %NULL to ignore.
 *
 * Completes a pigeon_melodink_melodink_host_player_api_info_audio_changed() call.
 *
 * Returns: a #PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse or %NULL on error.
 */
PigeonMelodinkMelodinkHostPlayerApiInfoAudioChangedResponse* pigeon_melodink_melodink_host_player_api_info_audio_changed_finish(PigeonMelodinkMelodinkHostPlayerApiInfo* api, GAsyncResult* result, GError** error);

/**
 * pigeon_melodink_melodink_host_player_api_info_update_state:
 * @api: a #PigeonMelodinkMelodinkHostPlayerApiInfo.
 * @state: parameter for this method.
 * @cancellable: (allow-none): a #GCancellable or %NULL.
 * @callback: (scope async): (allow-none): a #GAsyncReadyCallback to call when the call is complete or %NULL to ignore the response.
 * @user_data: (closure): user data to pass to @callback.
 *
 */
void pigeon_melodink_melodink_host_player_api_info_update_state(PigeonMelodinkMelodinkHostPlayerApiInfo* api, PigeonMelodinkMelodinkHostPlayerProcessingState state, GCancellable* cancellable, GAsyncReadyCallback callback, gpointer user_data);

/**
 * pigeon_melodink_melodink_host_player_api_info_update_state_finish:
 * @api: a #PigeonMelodinkMelodinkHostPlayerApiInfo.
 * @result: a #GAsyncResult.
 * @error: (allow-none): #GError location to store the error occurring, or %NULL to ignore.
 *
 * Completes a pigeon_melodink_melodink_host_player_api_info_update_state() call.
 *
 * Returns: a #PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse or %NULL on error.
 */
PigeonMelodinkMelodinkHostPlayerApiInfoUpdateStateResponse* pigeon_melodink_melodink_host_player_api_info_update_state_finish(PigeonMelodinkMelodinkHostPlayerApiInfo* api, GAsyncResult* result, GError** error);

G_END_DECLS

#endif  // PIGEON_MESSAGES_G_H_