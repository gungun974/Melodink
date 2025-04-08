import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/provider.dart';
import 'package:melodink_client/core/routes/routes.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/auth/domain/providers/auth_provider.dart';
import 'package:melodink_client/features/auth/domain/providers/server_setup_provider.dart';
import 'package:melodink_client/features/home/presentation/widgets/desktop_sidebar.dart';
import 'package:melodink_client/features/home/presentation/widgets/mobile_navbar.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop_player_bar.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_desktop_player_bar.dart';
import 'package:melodink_client/features/player/presentation/widgets/mobile_current_track.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/current_download_info.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _globalShellNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class GoRouterObserver extends NavigatorObserver {
  GoRouter? router;

  GoRouterObserver({required this.setCurrentUrl});

  setRouter(GoRouter router) {
    this.router = router;
  }

  final void Function(String? url) setCurrentUrl;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final router = this.router;
    if (router == null) {
      return;
    }
    setCurrentUrl(router.location);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final router = this.router;
    if (router == null) {
      return;
    }
    setCurrentUrl(router.location);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final router = this.router;
    if (router == null) {
      return;
    }
    setCurrentUrl(router.location);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final router = this.router;
    if (router == null) {
      return;
    }
    setCurrentUrl(router.location);
  }
}

final appRouterProvider = Provider((ref) {
  setCurrentUrl(String? url) {
    Future(() {
      ref.read(appRouterCurrentUrl.notifier).state = url;
    });
  }

  final routeObserver1 = GoRouterObserver(setCurrentUrl: setCurrentUrl);
  final routeObserver2 = GoRouterObserver(setCurrentUrl: setCurrentUrl);
  final routeObserver3 = GoRouterObserver(setCurrentUrl: setCurrentUrl);

  final router = GoRouter(
    initialLocation: "/",
    navigatorKey: _rootNavigatorKey,
    observers: [routeObserver1],
    redirect: (context, state) async {
      setCurrentUrl(state.matchedLocation);

      final isServerConfigured = ref.read(isServerConfiguredProvider);

      if (!isServerConfigured) {
        return "/auth/serverSetup";
      }

      final isAuthConfigured =
          await ref.read(isUserAuthenticatedProvider.future);

      if (!isAuthConfigured) {
        switch (state.matchedLocation) {
          case "/auth/serverSetup":
            return null;
          case "/auth/register":
            return null;
          default:
            return "/auth/login";
        }
      }

      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: _globalShellNavigatorKey,
        observers: [routeObserver2],
        builder: (context, state, child) {
          return AppScreenTypeLayoutBuilders(
            mobile: (BuildContext context) => child,
            desktop: (BuildContext context) {
              return Consumer(
                builder: (context, ref, _) {
                  final currentPlayerBarPosition =
                      ref.watch(currentPlayerBarPositionProvider);
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Column(
                      children: [
                        if (currentPlayerBarPosition ==
                            AppSettingPlayerBarPosition.top)
                          RepaintBoundary(
                            child: const DesktopPlayerBar(),
                          ),
                        Expanded(
                          child: Stack(
                            children: [
                              child,
                              const Align(
                                alignment: Alignment.bottomRight,
                                child: CurrentDownloadInfo(),
                              ),
                            ],
                          ),
                        ),
                        if (currentPlayerBarPosition ==
                            AppSettingPlayerBarPosition.bottom)
                          RepaintBoundary(
                            child: const DesktopPlayerBar(),
                          ),
                        if (currentPlayerBarPosition ==
                            AppSettingPlayerBarPosition.center)
                          RepaintBoundary(
                            child: const LargeDesktopPlayerBar(),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        routes: [
          ShellRoute(
            observers: [routeObserver3],
            navigatorKey: _shellNavigatorKey,
            builder: (context, state, child) {
              return AppScreenTypeLayoutBuilders(
                desktop: (BuildContext context) {
                  return Stack(
                    children: [
                      const GradientBackground(),
                      Scaffold(
                        resizeToAvoidBottomInset: false,
                        backgroundColor: Colors.transparent,
                        body: Stack(
                          children: [
                            Container(
                              color: const Color.fromRGBO(0, 0, 0, 0.15),
                              height: MediaQuery.paddingOf(context).top,
                            ),
                            SafeArea(
                              top: true,
                              bottom: false,
                              child: NotificationListener<
                                  OverscrollIndicatorNotification>(
                                onNotification: (OverscrollIndicatorNotification
                                    overscroll) {
                                  overscroll.disallowIndicator();
                                  return true;
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const DesktopSidebar(),
                                    Expanded(
                                      child: child,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                mobile: (BuildContext context) {
                  return Stack(
                    children: [
                      const GradientBackground(),
                      Scaffold(
                        resizeToAvoidBottomInset: false,
                        backgroundColor: Colors.transparent,
                        body: SafeArea(
                          child: NotificationListener<
                              OverscrollIndicatorNotification>(
                            onNotification:
                                (OverscrollIndicatorNotification overscroll) {
                              overscroll.disallowIndicator();
                              return true;
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      child,
                                      const Align(
                                        alignment: Alignment.bottomRight,
                                        child: CurrentDownloadInfo(),
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
                          data: Theme.of(context).copyWith(
                            splashColor: Colors.transparent,
                          ),
                          child: const MobileNavbar(),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (context, state, child) {
                  setCurrentUrl(GoRouter.of(context).location);
                  return child;
                },
                branches: [
                  StatefulShellBranch(
                    routes: appRoutesWithShell,
                  ),
                ],
              ),
            ],
          ),
          ...appRoutesWithDesktopPlayerShell
        ],
      ),
      ...appRoutesWithNoShell
    ],
  );

  routeObserver1.setRouter(router);
  routeObserver2.setRouter(router);
  routeObserver3.setRouter(router);

  return router;
});

extension GoRouterLocation on GoRouter {
  String? get location {
    final RouteMatch? lastMatch =
        routerDelegate.currentConfiguration.lastOrNull;
    if (lastMatch == null) {
      return null;
    }
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
