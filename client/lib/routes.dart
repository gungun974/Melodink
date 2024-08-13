import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/features/player/presentation/pages/test_player_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

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
  initialLocation: "/",
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/',
      name: "/",
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const TestPlayerPage(),
        transitionDuration: pageTransitonDuration,
        transitionsBuilder: slideUpTransitionBuilder,
      ),
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
