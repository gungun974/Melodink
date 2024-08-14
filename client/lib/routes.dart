import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/home/presentation/widgets/desktop_side_navbar.dart';
import 'package:melodink_client/features/home/presentation/widgets/mobile_navbar.dart';
import 'package:melodink_client/features/player/presentation/pages/player_page.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_page.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_widget.dart';
import 'package:melodink_client/features/track/presentation/pages/all_tracks_page.dart';
import 'package:responsive_builder/responsive_builder.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _globalShellNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

Duration pageTransitonDuration = const Duration(milliseconds: 450);

Widget slideUpTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: animation.drive(
      Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInQuad)),
    ),
    child: child,
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: "/tracks",
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _globalShellNavigatorKey,
      builder: (context, state, child) {
        return SafeArea(
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (OverscrollIndicatorNotification overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: ScreenTypeLayout.builder(
              mobile: (BuildContext context) => child,
              desktop: (BuildContext context) {
                return Scaffold(
                  body: Column(
                    children: [
                      Expanded(
                        child: child,
                      ),
                      AudioPlayerWidget(
                        location: GoRouter.of(context).location,
                      )
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
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return ScreenTypeLayout.builder(
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
                      AudioPlayerWidget(
                        location: GoRouter.of(context).location,
                      )
                    ],
                  ),
                  bottomNavigationBar: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                    ),
                    child: MobileNavbar(
                      location: GoRouter.of(context).location,
                    ),
                  ),
                );
              },
              desktop: (BuildContext context) {
                return Scaffold(
                  body: Stack(
                    children: [
                      const GradientBackground(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DesktopSideNavbar(
                            location: GoRouter.of(context).location,
                          ),
                          Expanded(
                            child: child,
                          ),
                        ],
                      ),
                    ],
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
                  routes: [
                    GoRoute(
                      path: '/tracks',
                      name: "/tracks",
                      builder: (BuildContext context, GoRouterState state) {
                        return const AllTracksPage();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/player',
          name: "/player",
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const PlayerPage(),
            transitionDuration: pageTransitonDuration,
            transitionsBuilder: slideUpTransitionBuilder,
          ),
        ),
        GoRoute(
          path: '/queue',
          name: "/queue",
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const QueuePage(),
            transitionDuration: pageTransitonDuration,
            transitionsBuilder: slideUpTransitionBuilder,
          ),
        ),
      ],
    ),
  ],
);

extension GoRouterLocation on GoRouter {
  String get location {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
