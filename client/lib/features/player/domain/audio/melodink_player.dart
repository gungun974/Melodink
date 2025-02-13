import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart' as ffi;
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
  final AppSettingAudioQuality quality;
  final String originalAudioHash;
  final String downloadedPath;

  MelodinkTrackRequest({
    required this.id,
    required this.quality,
    required this.originalAudioHash,
    required this.downloadedPath,
  });
}

final class NativeMelodinkTrackRequest extends ffi.Struct {
  external ffi.Pointer<ffi.Char> serverURL;
  external ffi.Pointer<ffi.Char> cachePath;
  @ffi.Int64()
  external int trackId;
  @ffi.Int64()
  external int quality;
  external ffi.Pointer<ffi.Char> originalAudioHash;
  external ffi.Pointer<ffi.Char> downloadedPath;
}

class MelodinkPlayer {
  MelodinkPlayer._privateConstructor();

  static final MelodinkPlayer _instance = MelodinkPlayer._privateConstructor();

  factory MelodinkPlayer() {
    return _instance;
  }

  late final ffi.DynamicLibrary _lib;

  init() {
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
          _initLibrary(ffi.DynamicLibrary.open(name));
          return;
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
    } else {
      throw Exception(
        'Unsupported operating system: ${Platform.operatingSystem}',
      );
    }
  }

  final _eventAudioChangedStreamController = StreamController<int>.broadcast();
  final _eventAudioChangedReceivePort = ReceivePort();

  Stream get eventAudioChangedStream =>
      _eventAudioChangedStreamController.stream;

  final _eventUpdateStateStreamController =
      StreamController<MelodinkProcessingState>.broadcast();
  final _eventUpdateStateReceivePort = ReceivePort();

  Stream get eventUpdateStateStream => _eventUpdateStateStreamController.stream;

  void _initLibrary(ffi.DynamicLibrary lib) {
    _lib = lib;
    final void Function() init = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('mi_player_init')
        .asFunction();

    final registerEventAudioChangedCallback = _lib.lookupFunction<
        Int64NativeSetCallbackFunction,
        Int64SetCallbackFunction>('mi_register_event_audio_changed_callback');

    final registerEventUpdateStateCallback = _lib.lookupFunction<
        Int64NativeSetCallbackFunction,
        Int64SetCallbackFunction>('mi_register_event_update_state_callback');

    _play = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('mi_player_play')
        .asFunction();
    _pause = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('mi_player_pause')
        .asFunction();
    _seek = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
            'mi_player_seek')
        .asFunction();
    _skipToPrevious = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>(
            'mi_player_skip_to_previous')
        .asFunction();
    _skipToNext = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>(
            'mi_player_skip_to_next')
        .asFunction();
    _setAudios = _lib
        .lookup<
            ffi.NativeFunction<
                ffi.Void Function(
                  ffi.Int64,
                  ffi.Int64,
                  ffi.Pointer<NativeMelodinkTrackRequest>,
                  ffi.Size,
                )>>('mi_player_set_audios')
        .asFunction();
    _setLoopMode = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>>(
            'mi_player_set_loop_mode')
        .asFunction();
    _setAuthToken = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Utf8>)>>(
            'mi_player_set_auth_token')
        .asFunction();
    _getCurrentPlaying = _lib
        .lookup<ffi.NativeFunction<ffi.Uint8 Function()>>(
            'mi_player_get_current_playing')
        .asFunction();
    _getCurrentTrackPos = _lib
        .lookup<ffi.NativeFunction<ffi.Int64 Function()>>(
            'mi_player_get_current_track_pos')
        .asFunction();
    _getCurrentPosition = _lib
        .lookup<ffi.NativeFunction<ffi.Int64 Function()>>(
            'mi_player_get_current_position')
        .asFunction();
    _getCurrentBufferedPosition = _lib
        .lookup<ffi.NativeFunction<ffi.Int64 Function()>>(
            'mi_player_get_current_buffered_position')
        .asFunction();
    _getCurrentPlayerState = _lib
        .lookup<ffi.NativeFunction<ffi.Int64 Function()>>(
            'mi_player_get_current_player_state')
        .asFunction();
    _getCurrentLoopMode = _lib
        .lookup<ffi.NativeFunction<ffi.Int64 Function()>>(
            'mi_player_get_current_loop_mode')
        .asFunction();

    _setVolume = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Double)>>(
            'mi_player_set_volume')
        .asFunction();
    _getVolume = _lib
        .lookup<ffi.NativeFunction<ffi.Double Function()>>(
            'mi_player_get_volume')
        .asFunction();

    _eventAudioChangedReceivePort.listen(
      (data) => _eventAudioChangedStreamController.add(data),
      onError: (error) => _eventAudioChangedStreamController.addError(error),
      onDone: () => _eventAudioChangedStreamController.close(),
    );

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

    init();
  }

  late final void Function() _play;
  late final void Function() _pause;
  late final void Function(int) _seek;
  late final void Function() _skipToPrevious;
  late final void Function() _skipToNext;

  late final void Function(
    int,
    int,
    ffi.Pointer<NativeMelodinkTrackRequest>,
    int,
  ) _setAudios;

  late final void Function(int) _setLoopMode;
  late final void Function(ffi.Pointer<ffi.Utf8>) _setAuthToken;

  late final int Function() _getCurrentPlaying;
  late final int Function() _getCurrentTrackPos;
  late final int Function() _getCurrentPosition;
  late final int Function() _getCurrentBufferedPosition;
  late final int Function() _getCurrentPlayerState;
  late final int Function() _getCurrentLoopMode;

  late final double Function() _getVolume;
  late final void Function(double) _setVolume;

  void play() => _play();
  void pause() => _pause();
  void seek(int positionMs) => _seek(positionMs);
  void skipToPrevious() => _skipToPrevious();
  void skipToNext() => _skipToNext();

  void setAudios(
    String serverURL,
    String cachePath,
    int newCurrentTrackIndex,
    int currentRequestIndex,
    List<MelodinkTrackRequest> requests,
  ) {
    final requestsPointers =
        ffi.calloc<NativeMelodinkTrackRequest>(requests.length);

    final serverURLPointer = serverURL.toNativeUtf8().cast<ffi.Char>();

    final cachePathPointer = cachePath.toNativeUtf8().cast<ffi.Char>();

    try {
      for (var i = 0; i < requests.length; i++) {
        requestsPointers[i].serverURL = serverURLPointer;
        requestsPointers[i].cachePath = cachePathPointer;
        requestsPointers[i].trackId = requests[i].id;
        requestsPointers[i].quality = switch (requests[i].quality) {
          AppSettingAudioQuality.lossless => 0,
          AppSettingAudioQuality.low => 1,
          AppSettingAudioQuality.medium => 2,
          AppSettingAudioQuality.high => 3,
        };
        requestsPointers[i].originalAudioHash =
            requests[i].originalAudioHash.toNativeUtf8().cast<ffi.Char>();
        requestsPointers[i].downloadedPath =
            requests[i].downloadedPath.toNativeUtf8().cast<ffi.Char>();
      }

      _setAudios(newCurrentTrackIndex, currentRequestIndex, requestsPointers,
          requests.length);
    } finally {
      for (var i = 0; i < requests.length; i++) {
        ffi.calloc.free(requestsPointers[i].originalAudioHash);
        ffi.calloc.free(requestsPointers[i].downloadedPath);
      }
      ffi.calloc.free(cachePathPointer);
      ffi.calloc.free(serverURLPointer);
      ffi.calloc.free(requestsPointers);
    }
  }

  void setLoopMode(MelodinkLoopMode loopMode) {
    _setLoopMode(loopMode.index);
  }

  void setAuthToken(String authToken) {
    final tokenPtr = authToken.toNativeUtf8();
    _setAuthToken(tokenPtr);
    ffi.calloc.free(tokenPtr);
  }

  bool getCurrentPlaying() => _getCurrentPlaying() != 0;
  int getCurrentTrackPos() => _getCurrentTrackPos();
  int getCurrentPosition() => _getCurrentPosition();
  int getCurrentBufferedPosition() => _getCurrentBufferedPosition();

  MelodinkProcessingState getCurrentPlayerState() {
    return MelodinkProcessingState.values[_getCurrentPlayerState()];
  }

  MelodinkLoopMode getCurrentLoopMode() {
    return MelodinkLoopMode.values[_getCurrentLoopMode()];
  }

  void setVolume(double volume) => _setVolume(volume);

  double getVolume() => _getVolume();
}
