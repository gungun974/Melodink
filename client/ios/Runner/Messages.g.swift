// Autogenerated from Pigeon (v21.1.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

/// Error class for passing custom error details to Dart side.
final class PigeonError: Error {
  let code: String
  let message: String?
  let details: Any?

  init(code: String, message: String?, details: Any?) {
    self.code = code
    self.message = message
    self.details = details
  }

  var localizedDescription: String {
    return
      "PigeonError(code: \(code), message: \(message ?? "<nil>"), details: \(details ?? "<nil>")"
      }
}

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let pigeonError = error as? PigeonError {
    return [
      pigeonError.code,
      pigeonError.message,
      pigeonError.details,
    ]
  }
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details,
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)",
  ]
}

private func createConnectionError(withChannelName channelName: String) -> PigeonError {
  return PigeonError(code: "channel-error", message: "Unable to establish connection on channel: '\(channelName)'.", details: "")
}

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

enum MelodinkHostPlayerProcessingState: Int {
  /// There hasn't been any resource loaded yet.
  case idle = 0
  /// Resource is being loaded.
  case loading = 1
  /// Resource is being buffered.
  case buffering = 2
  /// Resource is buffered enough and available for playback.
  case ready = 3
  /// The end of resource was reached.
  case completed = 4
}

enum MelodinkHostPlayerLoopMode: Int {
  /// The current media item or queue will not repeat.
  case none = 0
  /// The current media item will repeat.
  case one = 1
  /// Playback will continue looping through all media items in the current list.
  case all = 2
}

/// Generated class from Pigeon that represents data sent in messages.
struct PlayerStatus {
  var playing: Bool
  var pos: Int64
  var positionMs: Int64
  var bufferedPositionMs: Int64
  var state: MelodinkHostPlayerProcessingState
  var loop: MelodinkHostPlayerLoopMode

  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ __pigeon_list: [Any?]) -> PlayerStatus? {
    let playing = __pigeon_list[0] as! Bool
    let pos = __pigeon_list[1] is Int64 ? __pigeon_list[1] as! Int64 : Int64(__pigeon_list[1] as! Int32)
    let positionMs = __pigeon_list[2] is Int64 ? __pigeon_list[2] as! Int64 : Int64(__pigeon_list[2] as! Int32)
    let bufferedPositionMs = __pigeon_list[3] is Int64 ? __pigeon_list[3] as! Int64 : Int64(__pigeon_list[3] as! Int32)
    let state = __pigeon_list[4] as! MelodinkHostPlayerProcessingState
    let loop = __pigeon_list[5] as! MelodinkHostPlayerLoopMode

    return PlayerStatus(
      playing: playing,
      pos: pos,
      positionMs: positionMs,
      bufferedPositionMs: bufferedPositionMs,
      state: state,
      loop: loop
    )
  }
  func toList() -> [Any?] {
    return [
      playing,
      pos,
      positionMs,
      bufferedPositionMs,
      state,
      loop,
    ]
  }
}
private class MessagesPigeonCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
    case 129:
      return PlayerStatus.fromList(self.readValue() as! [Any?])
    case 130:
      var enumResult: MelodinkHostPlayerProcessingState? = nil
      let enumResultAsInt: Int? = nilOrValue(self.readValue() as? Int)
      if let enumResultAsInt = enumResultAsInt {
        enumResult = MelodinkHostPlayerProcessingState(rawValue: enumResultAsInt)
      }
      return enumResult
    case 131:
      var enumResult: MelodinkHostPlayerLoopMode? = nil
      let enumResultAsInt: Int? = nilOrValue(self.readValue() as? Int)
      if let enumResultAsInt = enumResultAsInt {
        enumResult = MelodinkHostPlayerLoopMode(rawValue: enumResultAsInt)
      }
      return enumResult
    default:
      return super.readValue(ofType: type)
    }
  }
}

private class MessagesPigeonCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? PlayerStatus {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else if let value = value as? MelodinkHostPlayerProcessingState {
      super.writeByte(130)
      super.writeValue(value.rawValue)
    } else if let value = value as? MelodinkHostPlayerLoopMode {
      super.writeByte(131)
      super.writeValue(value.rawValue)
    } else {
      super.writeValue(value)
    }
  }
}

private class MessagesPigeonCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return MessagesPigeonCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return MessagesPigeonCodecWriter(data: data)
  }
}

class MessagesPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
  static let shared = MessagesPigeonCodec(readerWriter: MessagesPigeonCodecReaderWriter())
}

/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol MelodinkHostPlayerApi {
  func play() throws
  func pause() throws
  func seek(positionMs: Int64) throws
  func skipToNext() throws
  func skipToPrevious() throws
  func setAudios(previousUrls: [String], nextUrls: [String]) throws
  func setLoopMode(loop: MelodinkHostPlayerLoopMode) throws
  func fetchStatus() throws -> PlayerStatus
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class MelodinkHostPlayerApiSetup {
  static var codec: FlutterStandardMessageCodec { MessagesPigeonCodec.shared }
  /// Sets up an instance of `MelodinkHostPlayerApi` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: MelodinkHostPlayerApi?, messageChannelSuffix: String = "") {
    let channelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
    let playChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.play\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      playChannel.setMessageHandler { _, reply in
        do {
          try api.play()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      playChannel.setMessageHandler(nil)
    }
    let pauseChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.pause\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      pauseChannel.setMessageHandler { _, reply in
        do {
          try api.pause()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      pauseChannel.setMessageHandler(nil)
    }
    let seekChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.seek\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      seekChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let positionMsArg = args[0] is Int64 ? args[0] as! Int64 : Int64(args[0] as! Int32)
        do {
          try api.seek(positionMs: positionMsArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      seekChannel.setMessageHandler(nil)
    }
    let skipToNextChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.skipToNext\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      skipToNextChannel.setMessageHandler { _, reply in
        do {
          try api.skipToNext()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      skipToNextChannel.setMessageHandler(nil)
    }
    let skipToPreviousChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.skipToPrevious\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      skipToPreviousChannel.setMessageHandler { _, reply in
        do {
          try api.skipToPrevious()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      skipToPreviousChannel.setMessageHandler(nil)
    }
    let setAudiosChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.setAudios\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      setAudiosChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let previousUrlsArg = args[0] as! [String]
        let nextUrlsArg = args[1] as! [String]
        do {
          try api.setAudios(previousUrls: previousUrlsArg, nextUrls: nextUrlsArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      setAudiosChannel.setMessageHandler(nil)
    }
    let setLoopModeChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.setLoopMode\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      setLoopModeChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let loopArg = args[0] as! MelodinkHostPlayerLoopMode
        do {
          try api.setLoopMode(loop: loopArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      setLoopModeChannel.setMessageHandler(nil)
    }
    let fetchStatusChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.fetchStatus\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      fetchStatusChannel.setMessageHandler { _, reply in
        do {
          let result = try api.fetchStatus()
          reply(wrapResult(result))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      fetchStatusChannel.setMessageHandler(nil)
    }
  }
}
/// Generated protocol from Pigeon that represents Flutter messages that can be called from Swift.
protocol MelodinkHostPlayerApiInfoProtocol {
  func audioChanged(pos posArg: Int64, completion: @escaping (Result<Void, PigeonError>) -> Void)
  func updateState(state stateArg: MelodinkHostPlayerProcessingState, completion: @escaping (Result<Void, PigeonError>) -> Void)
}
class MelodinkHostPlayerApiInfo: MelodinkHostPlayerApiInfoProtocol {
  private let binaryMessenger: FlutterBinaryMessenger
  private let messageChannelSuffix: String
  init(binaryMessenger: FlutterBinaryMessenger, messageChannelSuffix: String = "") {
    self.binaryMessenger = binaryMessenger
    self.messageChannelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
  }
  var codec: MessagesPigeonCodec {
    return MessagesPigeonCodec.shared
  }
  func audioChanged(pos posArg: Int64, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApiInfo.audioChanged\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([posArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
  func updateState(state stateArg: MelodinkHostPlayerProcessingState, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApiInfo.updateState\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([stateArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
}
