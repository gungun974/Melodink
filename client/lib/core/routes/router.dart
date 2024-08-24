import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/cubit.dart';
import 'package:melodink_client/core/routes/routes.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/home/presentation/widgets/desktop_sidebar.dart';
import 'package:melodink_client/features/home/presentation/widgets/mobile_navbar.dart';
import 'package:melodink_client/features/player/presentation/pages/test_player_page.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop_player_bar.dart';
import 'package:melodink_client/features/player/presentation/widgets/mobile_current_track.dart';
import 'package:melodink_client/injection_container.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _globalShellNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class GoRouterObserver extends NavigatorObserver {
  final RouterCubit routerCubit = sl();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routerCubit.setCurrentUrl(appRouter.location);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routerCubit.setCurrentUrl(appRouter.location);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routerCubit.setCurrentUrl(appRouter.location);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    routerCubit.setCurrentUrl(appRouter.location);
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: "/",
  navigatorKey: _rootNavigatorKey,
  observers: [GoRouterObserver()],
  routes: [
    ShellRoute(
      navigatorKey: _globalShellNavigatorKey,
      observers: [GoRouterObserver()],
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
          observers: [GoRouterObserver()],
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
                  routes: appRoutes,
                ),
              ],
            ),
          ],
        ),
        ...appOuterRoutes
      ],
    ),
    GoRoute(
      path: '/playerTest',
      name: "/playerTest",
      builder: (BuildContext context, GoRouterState state) {
        return const TestPlayerPage();
      },
    ),
  ],
);

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
