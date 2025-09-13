import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/routes/routes.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/server_setup_viewmodel.dart';
import 'package:melodink_client/features/home/presentation/widgets/desktop_sidebar.dart';
import 'package:melodink_client/features/home/presentation/widgets/mobile_navbar.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop_player_bar.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_desktop_player_bar.dart';
import 'package:melodink_client/features/player/presentation/widgets/mobile_current_track.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_debug_overlay.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/track/presentation/widgets/current_download_info.dart';
import 'package:provider/provider.dart';

enum AppRouteViewType { fullPage, playerBarPage, sideBarPage }

class AppRoute {
  final String path;

  final AppRouteViewType viewType;

  final Page Function(BuildContext, AppRouteData) pageBuilder;

  AppRoute({
    required this.path,
    required this.viewType,
    required this.pageBuilder,
  });
}

final Random _random = Random();

ValueKey<String> _getUniqueValueKey() {
  return ValueKey<String>(
    String.fromCharCodes(
      List<int>.generate(32, (_) => _random.nextInt(33) + 89),
    ),
  );
}

class AppRouteData {
  final String path;

  final Map<String, String> parameters;

  final Object? extra;

  ValueKey<String> pageKey;

  AppRouteData({
    required this.path,
    required this.parameters,
    required this.extra,
    ValueKey<String>? pageKey,
  }) : pageKey = pageKey ?? _getUniqueValueKey();

  AppRouteData copyWith({
    String? path,
    Map<String, String>? parameters,
    Object? extra,
  }) {
    return AppRouteData(
      path: path ?? this.path,
      parameters: parameters ?? this.parameters,
      extra: extra ?? this.extra,
      pageKey: pageKey,
    );
  }
}

class AppRouter extends ChangeNotifier {
  late final AppRouterDelegate delegate;

  late final AppRouteInformationParser routeInformationParser;

  AppRouter() {
    delegate = AppRouterDelegate(router: this);
    routeInformationParser = AppRouteInformationParser(router: this);
  }

  List<AppRouteData> navigationStack = [];

  void push(String path, {Object? extra}) {
    navigationStack.add(AppRouteData(path: path, parameters: {}, extra: extra));
    notifyListeners();
  }

  void pushReplacement(String path, {Object? extra}) {
    if (navigationStack.length == 1) {
      return;
    }
    navigationStack.removeLast();
    navigationStack.add(AppRouteData(path: path, parameters: {}, extra: extra));
    notifyListeners();
  }

  void pop() {
    if (navigationStack.length == 1) {
      return;
    }
    navigationStack.removeLast();
    notifyListeners();
  }

  void go(String path, {Object? extra}) {
    navigationStack = [AppRouteData(path: path, parameters: {}, extra: extra)];
    notifyListeners();
  }

  void setNavigationStack(List<AppRouteData> newNavigationStack) {
    if (newNavigationStack.isEmpty) {
      return;
    }
    navigationStack = [...newNavigationStack];
    notifyListeners();
  }

  bool canPop() {
    return navigationStack.length > 1;
  }

  String currentPath() {
    return navigationStack.last.path;
  }

  void refresh() {
    notifyListeners();
  }
}

class AppRouterDelegate implements RouterDelegate<List<AppRouteData>> {
  final AppRouter router;

  AppRouterDelegate({required this.router});

  @override
  void addListener(VoidCallback listener) {
    router.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    router.removeListener(listener);
  }

  final navigatorKey = GlobalKey();

  (AppRoute, Map<String, String>)? findAppRouteFromPath(String path) {
    final startArgument = Runes(":").first;
    final endArgument = Runes("/").first;

    final searchRunes = path.runes;

    outerLoop:
    for (var i = 0; i < routes.length; i++) {
      final route = routes[i];

      final List<int> patternRunes = route.path.runes.toList(growable: false);
      final List<int> queryRunes = searchRunes.toList(growable: false);

      int p = 0;
      int q = 0;
      final Map<String, String> params = <String, String>{};

      while (true) {
        final int? pc = (p < patternRunes.length) ? patternRunes[p] : null;
        final int? qc = (q < queryRunes.length) ? queryRunes[q] : null;

        if (pc == null && qc == null) break;

        if (pc == startArgument) {
          p++; // Skip `:`

          final int nameStart = p;
          while (p < patternRunes.length && patternRunes[p] != endArgument) {
            p++;
          }
          final String paramName = String.fromCharCodes(
            patternRunes.sublist(nameStart, p),
          );

          final int valueStart = q;
          while (q < queryRunes.length && queryRunes[q] != endArgument) {
            q++;
          }
          final String paramValue = String.fromCharCodes(
            queryRunes.sublist(valueStart, q),
          );

          params[paramName] = paramValue;

          continue;
        }

        if (pc != qc) {
          continue outerLoop;
        }

        p++;
        q++;
      }

      return (route, params);
    }

    return null;
  }

  Page<dynamic>? createPage(
    BuildContext context,
    AppRouteData appRouteData,
    AppRouteViewType viewType,
  ) {
    final result = findAppRouteFromPath(appRouteData.path);

    if (result == null) {
      return MaterialPage(
        child: Scaffold(body: Center(child: Text("404"))),
      );
    }

    final (appRoute, parameters) = result;

    if (appRoute.viewType != viewType) {
      return null;
    }

    return appRoute.pageBuilder(
      context,
      appRouteData.copyWith(parameters: parameters),
    );
  }

  List<Page<dynamic>> createPages(
    BuildContext context, {
    required AppRouteViewType viewType,
  }) {
    List<Page<dynamic>> pages = [];

    final navigationStack = router.navigationStack;

    for (int index = 0; index < navigationStack.length; index++) {
      final page = createPage(context, navigationStack[index], viewType);
      if (page != null) {
        pages.add(page);
      }
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    if (router.navigationStack.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppScreenTypeLayoutBuilders(
      mobile: (context) => buildMobile(context),
      desktop: (context) => buildDesktop(context),
    );
  }

  Widget buildMobile(BuildContext context) {
    final sideBarPages = createPages(
      context,
      viewType: AppRouteViewType.sideBarPage,
    );

    final playerBarPages = createPages(
      context,
      viewType: AppRouteViewType.playerBarPage,
    );

    final fullPages = createPages(context, viewType: AppRouteViewType.fullPage);

    final showPlayerDebugOverlay = context.select<SettingsViewModel, bool>(
      (viewModel) => viewModel.getShowPlayerDebugOverlay(),
    );

    return Navigator(
      key: navigatorKey,
      pages: [
        if (playerBarPages.isNotEmpty || sideBarPages.isNotEmpty)
          MaterialPage(
            key: ValueKey("FullPage"),
            child: Stack(
              children: [
                SafeArea(
                  top: false,
                  bottom: true,
                  child: Navigator(
                    pages: [
                      if (sideBarPages.isNotEmpty)
                        MaterialPage(
                          key: ValueKey("PlayerBarView"),
                          child: Stack(
                            children: [
                              const GradientBackground(),
                              Scaffold(
                                resizeToAvoidBottomInset: false,
                                backgroundColor: Colors.transparent,
                                body: SafeArea(
                                  child:
                                      NotificationListener<
                                        OverscrollIndicatorNotification
                                      >(
                                        onNotification:
                                            (
                                              OverscrollIndicatorNotification
                                              overscroll,
                                            ) {
                                              overscroll.disallowIndicator();
                                              return true;
                                            },
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  Navigator(
                                                    pages: sideBarPages,
                                                    // ignore: deprecated_member_use
                                                    onPopPage: (_, _) {
                                                      Future(() {
                                                        router.pop();
                                                      });
                                                      return false;
                                                    },
                                                  ),
                                                  const Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child:
                                                        CurrentDownloadInfo(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const MobileCurrentTrackInfo(),
                                          ],
                                        ),
                                      ),
                                ),
                                bottomNavigationBar: Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(splashColor: Colors.transparent),
                                  child: const MobileNavbar(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...playerBarPages,
                    ],
                    // ignore: deprecated_member_use
                    onPopPage: (_, _) {
                      Future(() {
                        router.pop();
                      });
                      return false;
                    },
                  ),
                ),
                if (showPlayerDebugOverlay)
                  IgnorePointer(
                    child: Scaffold(
                      body: PlayerDebugOverlay(),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
        ...fullPages,
      ],
      // ignore: deprecated_member_use
      onPopPage: (_, _) {
        Future(() {
          router.pop();
        });
        return false;
      },
    );
  }

  Widget buildDesktop(BuildContext context) {
    final sideBarPages = createPages(
      context,
      viewType: AppRouteViewType.sideBarPage,
    );

    final playerBarPages = createPages(
      context,
      viewType: AppRouteViewType.playerBarPage,
    );

    final fullPages = createPages(context, viewType: AppRouteViewType.fullPage);

    final currentPlayerBarPosition = context
        .select<SettingsViewModel, AppSettingPlayerBarPosition>(
          (viewModel) => viewModel.currentPlayerBarPosition(),
        );

    final showPlayerDebugOverlay = context.select<SettingsViewModel, bool>(
      (viewModel) => viewModel.getShowPlayerDebugOverlay(),
    );

    return Navigator(
      key: navigatorKey,
      pages: [
        if (playerBarPages.isNotEmpty || sideBarPages.isNotEmpty)
          MaterialPage(
            key: ValueKey("FullPage"),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: Column(
                children: [
                  if (currentPlayerBarPosition ==
                      AppSettingPlayerBarPosition.top)
                    RepaintBoundary(child: const DesktopPlayerBar()),
                  Expanded(
                    child: Stack(
                      children: [
                        Navigator(
                          pages: [
                            MaterialPage(
                              key: ValueKey("PlayerBarView"),
                              child: Stack(
                                children: [
                                  const GradientBackground(),
                                  Scaffold(
                                    resizeToAvoidBottomInset: false,
                                    backgroundColor: Colors.transparent,
                                    body: Stack(
                                      children: [
                                        Container(
                                          color: const Color.fromRGBO(
                                            0,
                                            0,
                                            0,
                                            0.15,
                                          ),
                                          height: MediaQuery.paddingOf(
                                            context,
                                          ).top,
                                        ),
                                        SafeArea(
                                          top: true,
                                          bottom: false,
                                          child:
                                              NotificationListener<
                                                OverscrollIndicatorNotification
                                              >(
                                                onNotification:
                                                    (
                                                      OverscrollIndicatorNotification
                                                      overscroll,
                                                    ) {
                                                      overscroll
                                                          .disallowIndicator();
                                                      return true;
                                                    },
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const DesktopSidebar(),
                                                    if (sideBarPages.isNotEmpty)
                                                      Expanded(
                                                        child: Navigator(
                                                          pages: sideBarPages,
                                                          // ignore: deprecated_member_use
                                                          onPopPage: (_, _) {
                                                            Future(() {
                                                              router.pop();
                                                            });
                                                            return false;
                                                          },
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...playerBarPages,
                          ],
                          // ignore: deprecated_member_use
                          onPopPage: (_, _) {
                            Future(() {
                              router.pop();
                            });
                            return false;
                          },
                        ),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: CurrentDownloadInfo(),
                        ),
                        if (showPlayerDebugOverlay) PlayerDebugOverlay(),
                      ],
                    ),
                  ),
                  if (currentPlayerBarPosition ==
                      AppSettingPlayerBarPosition.bottom)
                    RepaintBoundary(child: const DesktopPlayerBar()),
                  if (currentPlayerBarPosition ==
                      AppSettingPlayerBarPosition.center)
                    RepaintBoundary(child: const LargeDesktopPlayerBar()),
                ],
              ),
            ),
          ),
        ...fullPages,
      ],
      // ignore: deprecated_member_use
      onPopPage: (_, _) {
        Future(() {
          router.pop();
        });
        return false;
      },
    );
  }

  @override
  Future<bool> popRoute() async {
    if (router.navigationStack.length > 1) {
      Navigator.of(navigatorKey.currentContext!).pop();

      return SynchronousFuture(true);
    }

    return SynchronousFuture(false);
  }

  @override
  Future<void> setInitialRoutePath(configuration) async {
    if (configuration.isEmpty) {
      return;
    }
    router.setNavigationStack(configuration);
  }

  @override
  Future<void> setNewRoutePath(configuration) async {
    if (configuration.isEmpty) {
      return;
    }
    router.setNavigationStack(configuration);
  }

  @override
  Future<void> setRestoredRoutePath(configuration) async {
    if (configuration.isEmpty) {
      return;
    }
    router.setNavigationStack(configuration);
  }

  @override
  List<AppRouteData> get currentConfiguration {
    return router.navigationStack;
  }
}

class AppRouteInformationParser
    implements RouteInformationParser<List<AppRouteData>> {
  final AppRouter router;

  AppRouteInformationParser({required this.router});

  @override
  Future<List<AppRouteData>> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    throw UnimplementedError(
      'use parseRouteInformationWithDependencies instead',
    );
  }

  ServerSetupViewModel? serverSetupViewModel;
  AuthViewModel? authViewModel;

  @override
  Future<List<AppRouteData>> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) async {
    try {
      context.watch<AppRouter>();
    } catch (_) {}

    serverSetupViewModel ??= context.read<ServerSetupViewModel>();
    authViewModel ??= context.read<AuthViewModel>();

    final redirectResult = await redirect();
    if (redirectResult != null &&
        (router.navigationStack.isEmpty ||
            redirectResult != router.currentPath())) {
      return [AppRouteData(path: redirectResult, parameters: {}, extra: null)];
    }

    if (router.navigationStack.isNotEmpty &&
        routeInformation.uri.path == router.currentPath()) {
      return [];
    }

    return [
      AppRouteData(
        path: routeInformation.uri.path,
        parameters: {},
        extra: null,
      ),
    ];
  }

  FutureOr<String?> redirect() async {
    final isServerConfigured = serverSetupViewModel!.getIsServerConfigured();

    if (!isServerConfigured) {
      return "/auth/serverSetup";
    }

    await authViewModel!.waitForLoading();

    final isAuthConfigured = authViewModel!.getIsUserAuthenticated();

    if (!isAuthConfigured) {
      switch (router.navigationStack.isEmpty ? "" : router.currentPath()) {
        case "/auth/serverSetup":
          return null;
        case "/auth/register":
          return null;
        default:
          return "/auth/login";
      }
    }

    return null;
  }

  @override
  RouteInformation? restoreRouteInformation(configuration) {
    if (configuration.isEmpty) {
      return null;
    }
    return RouteInformation(uri: Uri(path: configuration.last.path));
  }
}
