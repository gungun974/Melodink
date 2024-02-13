import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/player/presentation/pages/player_page.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_page.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_widget.dart';
import 'package:melodink_client/features/playlist/presentation/widgets/playlist_list_sidebar.dart';
import 'package:melodink_client/features/tracks/presentation/pages/tracks_page.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:responsive_builder/responsive_builder.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _globalShellNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

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
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _globalShellNavigatorKey,
      builder: (context, state, child) {
        return BlocProvider(
          create: (_) => sl<PlayerCubit>(),
          child: SafeArea(
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
                          location: state.uri.path,
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return Scaffold(
              body: ScreenTypeLayout.builder(
                mobile: (BuildContext context) {
                  return Column(
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
                        location: state.uri.path,
                      )
                    ],
                  );
                },
                desktop: (BuildContext context) {
                  return Stack(
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
                  );
                },
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
          ],
        ),
        GoRoute(
          path: '/player',
          name: "/player",
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const PlayerPage(),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder: slideUpTransitionBuilder,
          ),
        ),
        GoRoute(
          path: '/queue',
          name: "/queue",
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const QueuePage(),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder: slideUpTransitionBuilder,
          ),
        ),
      ],
    ),
  ],
);
