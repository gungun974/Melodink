import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';

enum MelodinkProcessingState {
  /// There hasn't been any resource loaded yet.
  idle,

  /// Resource is being loaded.
  loading,

  /// Resource is being buffered.
  buffering,

  /// Resource is buffered enough and available for playback.
  ready,

  /// The end of resource was reached.
  completed,

  /// There was an error loading resource.
  error,
}

enum MelodinkLoopMode {
  /// The current media item or queue will not repeat.
  none,

  /// The current media item will repeat.
  one,

  /// Playback will continue looping through all media items in the current list.
  all,
}

typedef NativeInt64Callback = ffi.Void Function(ffi.Int64);

typedef Int64SetCallbackFunction = void Function(
    ffi.Pointer<ffi.NativeFunction<NativeInt64Callback>>);
typedef Int64NativeSetCallbackFunction = ffi.Void Function(
    ffi.Pointer<ffi.NativeFunction<NativeInt64Callback>>);

final class MelodinkTrackRequest {
  final int id;
  final String originalAudioHash;
  final String downloadedPath;

  MelodinkTrackRequest({
    required this.id,
    required this.originalAudioHash,
    required this.downloadedPath,
  });
}

final class NativeMelodinkTrackRequest extends ffi.Struct {
  external ffi.Pointer<ffi.Char> serverURL;
  external ffi.Pointer<ffi.Char> cachePath;
  @ffi.Uint64()
  external int trackId;
  external ffi.Pointer<ffi.Char> originalAudioHash;
  external ffi.Pointer<ffi.Char> downloadedPath;
}

class MelodinkPlayer {
  MelodinkPlayer._privateConstructor();

  static final MelodinkPlayer _instance = MelodinkPlayer._privateConstructor();

  factory MelodinkPlayer() {
    return _instance;
  }

  static ffi.DynamicLibrary getLibrary() {
    final names = {
      'windows': [
        'melodink_player.dll',
      ],
      'linux': [
        'libmelodink_player.so',
      ],
      'macos': [
        'MelodinkPlayer.framework/MelodinkPlayer',
      ],
      'ios': [
        'MelodinkPlayer.framework/MelodinkPlayer',
      ],
      'android': [
        'libmelodink_player.so',
      ],
    }[Platform.operatingSystem];
    if (names != null) {
      // Try to load the dynamic library from the system using [DynamicLibrary.open].
      for (final name in names) {
        try {
          return ffi.DynamicLibrary.open(name);
        } catch (_) {}
      }
      // If the dynamic library is not loaded, throw an [Exception].
      throw Exception(
        {
          'windows': 'Cannot find melodink_player.dll',
          'linux': 'Cannot find libmelodink_player.so',
          'macos': 'Cannot find MelodinkPlayer.framework/MelodinkPlayer.',
          'ios': 'Cannot find MelodinkPlayer.framework/MelodinkPlayer.',
          'android': 'Cannot find libmelodink_player.so.',
        }[Platform.operatingSystem]!,
      );
    }

    throw Exception(
      'Unsupported operating system: ${Platform.operatingSystem}',
    );
  }

  final _eventAudioChangedStreamController = StreamController<int>.broadcast();
  final _eventAudioChangedReceivePort = ReceivePort();

  Stream get eventAudioChangedStream =>
      _eventAudioChangedStreamController.stream;

  final _eventUpdateStateStreamController =
      StreamController<MelodinkProcessingState>.broadcast();
  final _eventUpdateStateReceivePort = ReceivePort();

  Stream get eventUpdateStateStream => _eventUpdateStateStreamController.stream;

  void init() {
    ffi.DynamicLibrary lib = getLibrary();
    final void Function() init = lib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('mi_player_init')
        .asFunction();

    final registerEventAudioChangedCallback = lib.lookupFunction<
        Int64NativeSetCallbackFunction,
        Int64SetCallbackFunction>('mi_register_event_audio_changed_callback');

    final registerEventUpdateStateCallback = lib.lookupFunction<
        Int64NativeSetCallbackFunction,
        Int64SetCallbackFunction>('mi_register_event_update_state_callback');

    _play = lib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('mi_player_play')
        .asFunction();
    _pause = lib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('mi_player_pause')
        .asFunction();
    _setLoopMode = lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Uint8)>>(
            'mi_player_set_loop_mode')
        .asFunction();
    _setQuality = lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Uint8)>>(
            'mi_player_set_quality')
        .asFunction();
    _setAuthToken = lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Utf8>)>>(
            'mi_player_set_auth_token')
        .asFunction();
    _getCurrentPlaying = lib
        .lookup<ffi.NativeFunction<ffi.Uint8 Function()>>(
            'mi_player_get_current_playing')
        .asFunction();
    _getCurrentTrackPos = lib
        .lookup<ffi.NativeFunction<ffi.Uint64 Function()>>(
            'mi_player_get_current_track_pos')
        .asFunction();
    _getCurrentPosition = lib
        .lookup<ffi.NativeFunction<ffi.Double Function()>>(
            'mi_player_get_current_position')
        .asFunction();
    _getCurrentBufferedPosition = lib
        .lookup<ffi.NativeFunction<ffi.Double Function()>>(
            'mi_player_get_current_buffered_position')
        .asFunction();
    _getCurrentPlayerState = lib
        .lookup<ffi.NativeFunction<ffi.Uint8 Function()>>(
            'mi_player_get_current_player_state')
        .asFunction();
    _getCurrentLoopMode = lib
        .lookup<ffi.NativeFunction<ffi.Uint8 Function()>>(
            'mi_player_get_current_loop_mode')
        .asFunction();

    _setVolume = lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Double)>>(
            'mi_player_set_volume')
        .asFunction();
    _getVolume = lib
        .lookup<ffi.NativeFunction<ffi.Double Function()>>(
            'mi_player_get_volume')
        .asFunction();

    _eventAudioChangedReceivePort.listen(
      (data) => _eventAudioChangedStreamController.add(data),
      onError: (error) => _eventAudioChangedStreamController.addError(error),
      onDone: () => _eventAudioChangedStreamController.close(),
    );

    init();

    final eventAudioChangedSendPort = _eventAudioChangedReceivePort.sendPort;

    final audioChangedSendPortNativeCallback =
        ffi.NativeCallable<NativeInt64Callback>.listener(
      (int value) {
        eventAudioChangedSendPort.send(value);
      },
    );

    registerEventAudioChangedCallback(
        audioChangedSendPortNativeCallback.nativeFunction);

    _eventUpdateStateReceivePort.listen(
      (data) => _eventUpdateStateStreamController.add(
        MelodinkProcessingState.values[data],
      ),
      onError: (error) => _eventUpdateStateStreamController.addError(error),
      onDone: () => _eventUpdateStateStreamController.close(),
    );

    final eventUpdateStateSendPort = _eventUpdateStateReceivePort.sendPort;

    final updateStateSendPortNativeCallback =
        ffi.NativeCallable<NativeInt64Callback>.listener(
      (int value) {
        eventUpdateStateSendPort.send(value);
      },
    );

    registerEventUpdateStateCallback(
        updateStateSendPortNativeCallback.nativeFunction);
  }

  late final void Function() _play;
  late final void Function() _pause;

  late final void Function(int) _setLoopMode;
  late final void Function(int) _setQuality;
  late final void Function(ffi.Pointer<ffi.Utf8>) _setAuthToken;

  late final int Function() _getCurrentPlaying;
  late final int Function() _getCurrentTrackPos;
  late final double Function() _getCurrentPosition;
  late final double Function() _getCurrentBufferedPosition;
  late final int Function() _getCurrentPlayerState;
  late final int Function() _getCurrentLoopMode;

  late final double Function() _getVolume;
  late final void Function(double) _setVolume;

  void play() => _play();
  void pause() => _pause();
  Future<void> seek(double position) async => compute((position) {
        final void Function(double) seek = getLibrary()
            .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Double)>>(
                'mi_player_seek')
            .asFunction();
        seek(position);
      }, position);

  Future<void> skipToPrevious() async => compute((_) {
        final void Function() skipToPrevious = getLibrary()
            .lookup<ffi.NativeFunction<ffi.Void Function()>>(
                'mi_player_skip_to_previous')
            .asFunction();
        skipToPrevious();
      }, null);
  Future<void> skipToNext() async => compute((_) {
        final void Function() skipToNext = getLibrary()
            .lookup<ffi.NativeFunction<ffi.Void Function()>>(
                'mi_player_skip_to_next')
            .asFunction();
        skipToNext();
      }, null);

  Future<void> setAudios(
    String serverURL,
    String cachePath,
    int newCurrentTrackIndex,
    int currentRequestIndex,
    List<MelodinkTrackRequest> requests,
  ) async {
    final requestsPointers =
        ffi.calloc<NativeMelodinkTrackRequest>(requests.length);

    final serverURLPointer = serverURL.toNativeUtf8().cast<ffi.Char>();

    final cachePathPointer = cachePath.toNativeUtf8().cast<ffi.Char>();

    try {
      for (var i = 0; i < requests.length; i++) {
        requestsPointers[i].serverURL = serverURLPointer;
        requestsPointers[i].cachePath = cachePathPointer;
        requestsPointers[i].trackId = requests[i].id;
        requestsPointers[i].originalAudioHash =
            requests[i].originalAudioHash.toNativeUtf8().cast<ffi.Char>();

        if (requests[i].downloadedPath.isNotEmpty) {
          requestsPointers[i].downloadedPath =
              requests[i].downloadedPath.toNativeUtf8().cast<ffi.Char>();
        } else {
          requestsPointers[i].downloadedPath = ffi.nullptr;
        }
      }

      await compute((data) {
        final void Function(
          int,
          int,
          ffi.Pointer<NativeMelodinkTrackRequest>,
          int,
        ) setAudios = getLibrary()
            .lookup<
                ffi.NativeFunction<
                    ffi.Void Function(
                      ffi.Size,
                      ffi.Size,
                      ffi.Pointer<NativeMelodinkTrackRequest>,
                      ffi.Size,
                    )>>('mi_player_set_audios')
            .asFunction();

        setAudios(
          data["newCurrentTrackIndex"]!,
          data["currentRequestIndex"]!,
          ffi.Pointer.fromAddress(data["requestsPointers"]!),
          data["len"]!,
        );
      }, {
        'newCurrentTrackIndex': newCurrentTrackIndex,
        'currentRequestIndex': currentRequestIndex,
        'requestsPointers': requestsPointers.address,
        'len': requests.length,
      });
    } finally {
      for (var i = 0; i < requests.length; i++) {
        ffi.calloc.free(requestsPointers[i].originalAudioHash);
        if (requests[i].downloadedPath.isNotEmpty) {
          ffi.calloc.free(requestsPointers[i].downloadedPath);
        }
      }
      ffi.calloc.free(cachePathPointer);
      ffi.calloc.free(serverURLPointer);
      ffi.calloc.free(requestsPointers);
    }
  }

  void setLoopMode(MelodinkLoopMode loopMode) {
    _setLoopMode(loopMode.index);
  }

  void setQuality(AppSettingAudioQuality quality) {
    _setQuality(switch (quality) {
      AppSettingAudioQuality.low => 0,
      AppSettingAudioQuality.medium => 1,
      AppSettingAudioQuality.high => 2,
      AppSettingAudioQuality.lossless => 3,
    });
  }

  void setAuthToken(String authToken) {
    final tokenPtr = authToken.toNativeUtf8();
    _setAuthToken(tokenPtr);
    ffi.calloc.free(tokenPtr);
  }

  bool getCurrentPlaying() => _getCurrentPlaying() != 0;
  int getCurrentTrackPos() => _getCurrentTrackPos();
  double getCurrentPosition() => _getCurrentPosition();
  double getCurrentBufferedPosition() => _getCurrentBufferedPosition();

  MelodinkProcessingState getCurrentPlayerState() {
    return MelodinkProcessingState.values[_getCurrentPlayerState()];
  }

  MelodinkLoopMode getCurrentLoopMode() {
    return MelodinkLoopMode.values[_getCurrentLoopMode()];
  }

  void setVolume(double volume) => _setVolume(volume);

  double getVolume() => _getVolume();
}
