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
@FlutterApi()
abstract class MelodinkHostPlayerApiInfo {
  void externalPause();
}
