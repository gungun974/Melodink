import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/messages.g.dart',
  dartOptions: DartOptions(),
  cppOptions: CppOptions(namespace: 'pigeon_melodink'),
  cppHeaderOut: 'windows/runner/messages.g.h',
  cppSourceOut: 'windows/runner/messages.g.cpp',
  gobjectHeaderOut: 'linux/messages.g.h',
  gobjectSourceOut: 'linux/messages.g.cc',
  gobjectOptions: GObjectOptions(),
  kotlinOut: 'android/app/src/main/kotlin/fr/gungun974/melodink/Messages.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/Messages.g.swift',
  swiftOptions: SwiftOptions(),
  objcHeaderOut: 'macos/Runner/messages.g.h',
  objcSourceOut: 'macos/Runner/messages.g.m',
  // Set this to a unique prefix for your plugin or application, per Objective-C naming conventions.
  objcOptions: ObjcOptions(prefix: 'PGN'),
  dartPackageName: 'pigeon_melodink',
))
enum MelodinkHostPlayerProcessingState {
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
}

enum MelodinkHostPlayerLoopMode {
  /// The current media item or queue will not repeat.
  none,

  /// The current media item will repeat.
  one,

  /// Playback will continue looping through all media items in the current list.
  all,
}

class PlayerStatus {
  PlayerStatus({
    required this.playing,
    required this.pos,
    required this.positionMs,
    required this.bufferedPositionMs,
    required this.state,
    required this.loop,
  });

  bool playing;
  int pos;
  int positionMs;
  int bufferedPositionMs;
  MelodinkHostPlayerProcessingState state;
  MelodinkHostPlayerLoopMode loop;
}

@HostApi()
abstract class MelodinkHostPlayerApi {
  void play();

  void pause();

  void seek(int positionMs);

  void skipToNext();

  void skipToPrevious();

  void setAudios(List<String> previousUrls, List<String> nextUrls);

  void setLoopMode(MelodinkHostPlayerLoopMode loop);

  PlayerStatus fetchStatus();

  void setAuthToken(String authToken);
}

@FlutterApi()
abstract class MelodinkHostPlayerApiInfo {
  void audioChanged(int pos);

  void updateState(MelodinkHostPlayerProcessingState state);

  void externalPause();
}
