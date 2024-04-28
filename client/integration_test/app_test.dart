import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/audio/audio_media_kit.dart'
    if (dart.library.html) 'package:melodink_client/core/audio/audio_media_kit_web.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';

import 'package:melodink_client/injection_container.dart' as di;
import 'package:melodink_client/routes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'helpers/async_wait.dart';
import 'tests/all_tracks_list_tester.dart';
import 'tests/player_tester.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  pageTransitonDuration = Duration.zero;

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (kIsWeb) {
    // Initialize FFI
    databaseFactoryOrNull = databaseFactoryFfiWeb;
  }

  setupMediaKit();

  await di.setup();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    // await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(300, 534),
      fullScreen: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions);
  }

  setUp(() async {
    await DatabaseService.getDatabase();

    if (di.sl.isRegistered<AudioHandler>()) {
      di.sl.unregister<AudioHandler>();
    }

    di.sl.registerSingleton<AudioHandler>(MyAudioHandler());

    if (di.sl.isRegistered<PlayerCubit>()) {
      di.sl.unregister<PlayerCubit>();
    }

    di.sl.registerLazySingleton(
      () => PlayerCubit(
        playedTrackRepository: di.sl(),
        audioHandler: di.sl(),
        shuffler: di.sl(),
      ),
    );
  });

  tearDown(() async {
    await wait(100);

    AudioHandler audioHandler = di.sl();

    if (audioHandler is MyAudioHandler) {
      await audioHandler.dispose();
    }
  });

  // group('AllTracksListTests', allTracksListTests);
  group('PlayerTests', playerTests);
}
