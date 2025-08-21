import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/auth/domain/providers/auth_provider.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/domain/audio/melodink_player.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/sync/domain/providers/sync_manager_provider.dart';
import 'package:melodink_client/features/tracker/domain/providers/shared_played_track_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;

void main() async {
  MelodinkPlayer().init();

  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();

  timeago.setLocaleMessages('fr', timeago.FrShortMessages());

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: Platform.isLinux
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      minimumSize: kReleaseMode ? const Size(972, 534) : const Size(300, 534),
      size: const Size(1200, 720),
      fullScreen: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions);
  }

  try {
    await DatabaseService.getDatabase();
  } catch (_) {}

  await AppApi().setupCookieJar();

  await AppApi().configureDio();

  await NetworkInfo().setSavedForceOffline();

  await initAudioService();

  PaintingBinding.instance.imageCache
    ..maximumSize = 10000
    ..maximumSizeBytes = 50 * 1024 * 1024; // 50 MB

  try {
    await ImageCacheManager.initCache();
  } catch (_) {}

  runApp(
    riverpod.ProviderScope(child: TranslationProvider(child: const MyApp())),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _EagerInitialization(
      child: _DynamicSystemUIMode(
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1)),
          child: riverpod.Consumer(
            builder: (contex, ref, _) {
              final appRouter = ref.watch(appRouterProvider);

              ref.listen(isUserAuthenticatedProvider, (prev, next) {
                final prevValue = prev?.valueOrNull ?? false;
                final nextValue = next.valueOrNull ?? false;

                if (prevValue && !nextValue) {
                  appRouter.refresh();
                }
              });

              final audioController = ref.watch(audioControllerProvider);

              return Shortcuts(
                shortcuts: <ShortcutActivator, Intent>{
                  const SingleActivator(
                    LogicalKeyboardKey.space,
                  ): VoidCallbackIntent(() {
                    if (audioController.playbackState.valueOrNull?.playing ==
                        true) {
                      audioController.pause();
                      return;
                    }
                    audioController.play();
                  }),
                },
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    MaterialApp.router(
                      title: 'Melodink Client',
                      locale: TranslationProvider.of(context).flutterLocale,
                      supportedLocales: AppLocaleUtils.supportedLocales,
                      localizationsDelegates:
                          GlobalMaterialLocalizations.delegates,
                      debugShowCheckedModeBanner: false,
                      theme: ThemeData(
                        useMaterial3: false,
                        brightness: Brightness.dark,
                        appBarTheme: const AppBarTheme(
                          backgroundColor: Colors.black,
                        ),
                        primaryColor: Colors.black,
                        iconTheme: const IconThemeData().copyWith(
                          color: Colors.white,
                        ),
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: const Color.fromRGBO(196, 126, 208, 1),
                          brightness: Brightness.dark,
                        ),
                        fontFamily: "Roboto",
                      ),
                      routerConfig: appRouter,
                    ),
                    RepaintBoundary(
                      child: AppNotificationManager(
                        key: appNotificationManagerKey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EagerInitialization extends riverpod.ConsumerWidget {
  const _EagerInitialization({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    ref.watch(audioControllerProvider);
    ref.watch(sharedPlayedTrackerManagerProvider);
    ref.watch(syncManagerProvider);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(
            audioController: ref.read(audioControllerProvider),
          )..loadSettings(),
        ),
      ],
      child: child,
    );
  }
}

class _DynamicSystemUIMode extends riverpod.HookConsumerWidget {
  const _DynamicSystemUIMode({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final currentPlayerBarPosition = context
        .watch<SettingsViewModel>()
        .currentPlayerBarPosition();

    final hide = useState(false);

    return AppScreenTypeLayoutBuilder(
      builder: (context, type) {
        if (type == AppScreenTypeLayout.desktop &&
            currentPlayerBarPosition == AppSettingPlayerBarPosition.bottom) {
          if (!hide.value) {
            if (!kIsWeb && Platform.isIOS) {
              SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.manual,
                overlays: [SystemUiOverlay.top],
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              hide.value = true;
            });
          }
        } else {
          if (hide.value) {
            if (!kIsWeb && Platform.isIOS) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              hide.value = false;
            });
          }
        }

        return child;
      },
    );
  }
}
