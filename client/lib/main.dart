import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/audio/audio_media_kit.dart'
    if (dart.library.html) 'package:melodink_client/core/audio/audio_media_kit_web.dart';
import 'package:melodink_client/core/audio/audio_mpris.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/routes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (kIsWeb) {
    // Initialize FFI
    databaseFactoryOrNull = databaseFactoryFfiWeb;
  }

  await DatabaseService.getDatabase();

  setupMediaKit();

  await di.setup();

  if (!kIsWeb && Platform.isLinux) {
    await initAudioMPRIS();
  }

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(300, 534),
      fullScreen: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Melodink Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        primaryColor: Colors.black,
        iconTheme: const IconThemeData().copyWith(color: Colors.white),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(196, 126, 208, 1),
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
