import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/animation.dart';
import 'package:melodink_client/features/auth/presentation/pages/login_page.dart';
import 'package:melodink_client/features/auth/presentation/pages/register_page.dart';
import 'package:melodink_client/features/auth/presentation/pages/select_server_page.dart';
import 'package:melodink_client/features/home/presentation/pages/home_page.dart';
import 'package:melodink_client/features/player/presentation/pages/mobile_player_page.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_page.dart';
import 'package:melodink_client/features/player/presentation/pages/test_player_page.dart';

final List<RouteBase> appRoutesWithShell = [
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

final List<RouteBase> appRoutesWithDesktopPlayerShell = [
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

final List<RouteBase> appRoutesWithNoShell = [
  GoRoute(
    path: '/auth/serverSetup',
    name: "/auth/serverSetup",
    builder: (BuildContext context, GoRouterState state) {
      return const SelectServerPage();
    },
  ),
  GoRoute(
    path: '/auth/login',
    name: "/auth/login",
    builder: (BuildContext context, GoRouterState state) {
      return const LoginPage();
    },
  ),
  GoRoute(
    path: '/auth/register',
    name: "/auth/register",
    builder: (BuildContext context, GoRouterState state) {
      return const RegisterPage();
    },
  ),
  GoRoute(
    path: '/playerTest',
    name: "/playerTest",
    builder: (BuildContext context, GoRouterState state) {
      return const TestPlayerPage();
    },
  ),
];
