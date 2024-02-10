import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_page.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_widget.dart';
import 'package:melodink_client/features/playlist/presentation/widgets/playlist_list_sidebar.dart';
import 'package:melodink_client/features/tracks/presentation/pages/tracks_page.dart';
import 'package:melodink_client/injection_container.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return Scaffold(
          body: BlocProvider(
            create: (_) => sl<PlayerCubit>(),
            child: Column(children: [
              Expanded(
                child: Stack(
                  children: [
                    const GradientBackground(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PlaylistListSidebar(),
                        Expanded(
                          child: child,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AudioPlayerWidget(
                location: state.uri.path,
              )
            ]),
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          name: "/",
          builder: (BuildContext context, GoRouterState state) {
            return const TracksPage();
          },
        ),
        GoRoute(
          path: '/queue',
          name: "/queue",
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const QueuePage(),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInQuad)),
              ),
              child: child,
            ),
          ),
        ),
      ],
    ),
  ],
);
