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
import 'package:melodink_client/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/domain/audio/melodink_player.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:melodink_client/provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  runApp(MainProviderScope(child: TranslationProvider(child: const MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _DynamicSystemUIMode(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1)),
        child: HookBuilder(
          builder: (context) {
            final appRouter = context.read<AppRouter>();

            final authViewModel = context.read<AuthViewModel>();

            final prevRef = useRef<bool?>(null);

            useOnListenableChange(authViewModel, () {
              final prevValue = prevRef.value ?? false;
              final nextValue = authViewModel.getIsUserAuthenticated();
              prevRef.value = nextValue;

              if (prevValue && !nextValue) {
                appRouter.refresh();
              }
            });

            final audioController = context.read<AudioController>();

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
                    routerDelegate: appRouter.delegate,
                    routeInformationParser: appRouter.routeInformationParser,
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
    );
  }
}

class _DynamicSystemUIMode extends HookWidget {
  const _DynamicSystemUIMode({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
