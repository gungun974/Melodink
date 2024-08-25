// Autogenerated from Pigeon (v21.1.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#ifndef PIGEON_MESSAGES_G_H_
#define PIGEON_MESSAGES_G_H_
#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>

namespace pigeon_melodink {


// Generated class from Pigeon.

class FlutterError {
 public:
  explicit FlutterError(const std::string& code)
    : code_(code) {}
  explicit FlutterError(const std::string& code, const std::string& message)
    : code_(code), message_(message) {}
  explicit FlutterError(const std::string& code, const std::string& message, const flutter::EncodableValue& details)
    : code_(code), message_(message), details_(details) {}

  const std::string& code() const { return code_; }
  const std::string& message() const { return message_; }
  const flutter::EncodableValue& details() const { return details_; }

 private:
  std::string code_;
  std::string message_;
  flutter::EncodableValue details_;
};

template<class T> class ErrorOr {
 public:
  ErrorOr(const T& rhs) : v_(rhs) {}
  ErrorOr(const T&& rhs) : v_(std::move(rhs)) {}
  ErrorOr(const FlutterError& rhs) : v_(rhs) {}
  ErrorOr(const FlutterError&& rhs) : v_(std::move(rhs)) {}

  bool has_error() const { return std::holds_alternative<FlutterError>(v_); }
  const T& value() const { return std::get<T>(v_); };
  const FlutterError& error() const { return std::get<FlutterError>(v_); };

 private:
  friend class MelodinkHostPlayerApi;
  friend class MelodinkHostPlayerApiInfo;
  ErrorOr() = default;
  T TakeValue() && { return std::get<T>(std::move(v_)); }

  std::variant<T, FlutterError> v_;
};


enum class MelodinkHostPlayerProcessingState {
  // There hasn't been any resource loaded yet.
  kIdle = 0,
  // Resource is being loaded.
  kLoading = 1,
  // Resource is being buffered.
  kBuffering = 2,
  // Resource is buffered enough and available for playback.
  kReady = 3,
  // The end of resource was reached.
  kCompleted = 4
};

enum class MelodinkHostPlayerLoopMode {
  // The current media item or queue will not repeat.
  kNone = 0,
  // The current media item will repeat.
  kOne = 1,
  // Playback will continue looping through all media items in the current list.
  kAll = 2
};

// Generated class from Pigeon that represents data sent in messages.
class PlayerStatus {
 public:
  // Constructs an object setting all fields.
  explicit PlayerStatus(
    bool playing,
    int64_t pos,
    int64_t position_ms,
    int64_t buffered_position_ms,
    const MelodinkHostPlayerProcessingState& state,
    const MelodinkHostPlayerLoopMode& loop);

  bool playing() const;
  void set_playing(bool value_arg);

  int64_t pos() const;
  void set_pos(int64_t value_arg);

  int64_t position_ms() const;
  void set_position_ms(int64_t value_arg);

  int64_t buffered_position_ms() const;
  void set_buffered_position_ms(int64_t value_arg);

  const MelodinkHostPlayerProcessingState& state() const;
  void set_state(const MelodinkHostPlayerProcessingState& value_arg);

  const MelodinkHostPlayerLoopMode& loop() const;
  void set_loop(const MelodinkHostPlayerLoopMode& value_arg);


 private:
  static PlayerStatus FromEncodableList(const flutter::EncodableList& list);
  flutter::EncodableList ToEncodableList() const;
  friend class MelodinkHostPlayerApi;
  friend class MelodinkHostPlayerApiInfo;
  friend class PigeonCodecSerializer;
  bool playing_;
  int64_t pos_;
  int64_t position_ms_;
  int64_t buffered_position_ms_;
  MelodinkHostPlayerProcessingState state_;
  MelodinkHostPlayerLoopMode loop_;

};

class PigeonCodecSerializer : public flutter::StandardCodecSerializer {
 public:
  PigeonCodecSerializer();
  inline static PigeonCodecSerializer& GetInstance() {
    static PigeonCodecSerializer sInstance;
    return sInstance;
  }

  void WriteValue(
    const flutter::EncodableValue& value,
    flutter::ByteStreamWriter* stream) const override;

 protected:
  flutter::EncodableValue ReadValueOfType(
    uint8_t type,
    flutter::ByteStreamReader* stream) const override;

};

// Generated interface from Pigeon that represents a handler of messages from Flutter.
class MelodinkHostPlayerApi {
 public:
  MelodinkHostPlayerApi(const MelodinkHostPlayerApi&) = delete;
  MelodinkHostPlayerApi& operator=(const MelodinkHostPlayerApi&) = delete;
  virtual ~MelodinkHostPlayerApi() {}
  virtual std::optional<FlutterError> Play() = 0;
  virtual std::optional<FlutterError> Pause() = 0;
  virtual std::optional<FlutterError> Seek(int64_t position_ms) = 0;
  virtual std::optional<FlutterError> SkipToNext() = 0;
  virtual std::optional<FlutterError> SkipToPrevious() = 0;
  virtual std::optional<FlutterError> SetAudios(
    const flutter::EncodableList& previous_urls,
    const flutter::EncodableList& next_urls) = 0;
  virtual std::optional<FlutterError> SetLoopMode(const MelodinkHostPlayerLoopMode& loop) = 0;
  virtual ErrorOr<PlayerStatus> FetchStatus() = 0;

  // The codec used by MelodinkHostPlayerApi.
  static const flutter::StandardMessageCodec& GetCodec();
  // Sets up an instance of `MelodinkHostPlayerApi` to handle messages through the `binary_messenger`.
  static void SetUp(
    flutter::BinaryMessenger* binary_messenger,
    MelodinkHostPlayerApi* api);
  static void SetUp(
    flutter::BinaryMessenger* binary_messenger,
    MelodinkHostPlayerApi* api,
    const std::string& message_channel_suffix);
  static flutter::EncodableValue WrapError(std::string_view error_message);
  static flutter::EncodableValue WrapError(const FlutterError& error);

 protected:
  MelodinkHostPlayerApi() = default;

};
// Generated class from Pigeon that represents Flutter messages that can be called from C++.
class MelodinkHostPlayerApiInfo {
 public:
  MelodinkHostPlayerApiInfo(flutter::BinaryMessenger* binary_messenger);
  MelodinkHostPlayerApiInfo(
    flutter::BinaryMessenger* binary_messenger,
    const std::string& message_channel_suffix);
  static const flutter::StandardMessageCodec& GetCodec();
  void AudioChanged(
    int64_t pos,
    std::function<void(void)>&& on_success,
    std::function<void(const FlutterError&)>&& on_error);
  void UpdateState(
    const MelodinkHostPlayerProcessingState& state,
    std::function<void(void)>&& on_success,
    std::function<void(const FlutterError&)>&& on_error);

 private:
  flutter::BinaryMessenger* binary_messenger_;
  std::string message_channel_suffix_;
};

}  // namespace pigeon_melodink
#endif  // PIGEON_MESSAGES_G_H_