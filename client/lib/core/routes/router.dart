import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/cubit.dart';
import 'package:melodink_client/core/routes/routes.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/auth/domain/providers/auth_provider.dart';
import 'package:melodink_client/features/auth/domain/providers/server_setup_provider.dart';
import 'package:melodink_client/features/home/presentation/widgets/desktop_sidebar.dart';
import 'package:melodink_client/features/home/presentation/widgets/mobile_navbar.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop_player_bar.dart';
import 'package:melodink_client/features/player/presentation/widgets/mobile_current_track.dart';
import 'package:melodink_client/injection_container.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _globalShellNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class GoRouterObserver extends NavigatorObserver {
  GoRouter? router;

  final RouterCubit routerCubit = sl();

  setRouter(GoRouter router) {
    this.router = router;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final router = this.router;
    if (router == null) {
      return;
    }
    routerCubit.setCurrentUrl(router.location);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final router = this.router;
    if (router == null) {
      return;
    }
    routerCubit.setCurrentUrl(router.location);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final router = this.router;
    if (router == null) {
      return;
    }
    routerCubit.setCurrentUrl(router.location);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final router = this.router;
    if (router == null) {
      return;
    }
    routerCubit.setCurrentUrl(router.location);
  }
}

final appRouterProvider = Provider((ref) {
  final routeObserver1 = GoRouterObserver();
  final routeObserver2 = GoRouterObserver();
  final routeObserver3 = GoRouterObserver();

  final router = GoRouter(
    initialLocation: "/",
    navigatorKey: _rootNavigatorKey,
    observers: [routeObserver1],
    redirect: (context, state) async {
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
          return SafeArea(
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (OverscrollIndicatorNotification overscroll) {
                overscroll.disallowIndicator();
                return true;
              },
              child: AppScreenTypeLayoutBuilders(
                mobile: (BuildContext context) => child,
                desktop: (BuildContext context) {
                  return Scaffold(
                    body: Column(
                      children: [
                        Expanded(
                          child: child,
                        ),
                        const DesktopPlayerBar(),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
        routes: [
          ShellRoute(
            observers: [routeObserver3],
            navigatorKey: _shellNavigatorKey,
            builder: (context, state, child) {
              return AppScreenTypeLayoutBuilders(
                desktop: (BuildContext context) {
                  return Scaffold(
                    body: Stack(
                      children: [
                        const GradientBackground(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const DesktopSidebar(),
                            Expanded(
                              child: child,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                mobile: (BuildContext context) {
                  return Scaffold(
                    body: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              const GradientBackground(),
                              child,
                            ],
                          ),
                        ),
                        const MobileCurrentTrackInfo()
                      ],
                    ),
                    bottomNavigationBar: Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                      ),
                      child: const MobileNavbar(),
                    ),
                  );
                },
              );
            },
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (context, state, child) {
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
