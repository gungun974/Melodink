import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/animation.dart';
import 'package:melodink_client/features/home/presentation/pages/home_page.dart';
import 'package:melodink_client/features/player/presentation/pages/mobile_player_page.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_page.dart';

final List<RouteBase> appRoutes = [
  GoRoute(
    path: '/',
    name: "/",
    builder: (BuildContext context, GoRouterState state) {
      return const HomePage();
    },
  ),
  GoRoute(
    path: '/tracks',
    name: "/tracks",
    builder: (BuildContext context, GoRouterState state) {
      return Container();
    },
  ),
];

final List<RouteBase> appOuterRoutes = [
  GoRoute(
    path: '/player',
    name: "/player",
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: const MobilePlayerPage(),
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
];
