import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/features/auth/domain/providers/auth_provider.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

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

  try {
    await DatabaseService.getDatabase();
  } catch (_) {}

  await AppApi().setupCookieJar();

  await AppApi().configureDio();

  await initAudioService();

  PaintingBinding.instance.imageCache
    ..maximumSize = 10000
    ..maximumSizeBytes = 750 * 1024 * 1024; // 750 MB

  if (!kIsWeb && Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _EagerInitialization(
      child: Consumer(
        builder: (contex, ref, _) {
          final appRouter = ref.watch(appRouterProvider);

          ref.listen(isUserAuthenticatedProvider, (prev, next) {
            final prevValue = prev?.valueOrNull ?? false;
            final nextValue = next.valueOrNull ?? false;

            if (prevValue && !nextValue) {
              appRouter.refresh();
            }
          });

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
              fontFamily: "Roboto",
            ),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}

class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(audioControllerProvider);
    return child;
  }
}
