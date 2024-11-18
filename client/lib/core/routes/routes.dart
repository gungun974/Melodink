import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/animation.dart';
import 'package:melodink_client/features/auth/presentation/pages/login_page.dart';
import 'package:melodink_client/features/auth/presentation/pages/register_page.dart';
import 'package:melodink_client/features/auth/presentation/pages/select_server_page.dart';
import 'package:melodink_client/features/home/presentation/pages/home_page.dart';
import 'package:melodink_client/features/library/presentation/pages/album_page.dart';
import 'package:melodink_client/features/library/presentation/pages/albums_page.dart';
import 'package:melodink_client/features/library/presentation/pages/artist_page.dart';
import 'package:melodink_client/features/library/presentation/pages/artists_page.dart';
import 'package:melodink_client/features/library/presentation/pages/playlist_page.dart';
import 'package:melodink_client/features/library/presentation/pages/playlists_page.dart';
import 'package:melodink_client/features/player/presentation/pages/mobile_player_page.dart';
import 'package:melodink_client/features/player/presentation/pages/player_page.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_and_history_page.dart';
import 'package:melodink_client/features/settings/presentation/pages/settings_page.dart';
import 'package:melodink_client/features/track/presentation/pages/tracks_page.dart';

final List<RouteBase> appRoutesWithShell = [
  GoRoute(
    path: '/',
    name: "/",
    pageBuilder: (BuildContext context, GoRouterState state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const HomePage(),
      );
    },
  ),
  GoRoute(
    path: '/track',
    name: "/track",
    pageBuilder: (BuildContext context, GoRouterState state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const TracksPage(),
      );
    },
  ),
  GoRoute(
    path: '/album',
    name: "/album",
    pageBuilder: (BuildContext context, GoRouterState state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const AlbumsPage(),
      );
    },
    routes: [
      GoRoute(
        path: ':id',
        name: "/album/:id",
        pageBuilder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['id']!;

          final extraData = state.extra as Map<String, dynamic>?;

          final int? trackId =
              extraData?['openWithScrollOnSpecificTrackId'] as int?;

          return NoTransitionPage(
            key: state.pageKey,
            child: AlbumPage(
              albumId: id,
              openWithScrollOnSpecificTrackId: trackId,
            ),
          );
        },
      ),
    ],
  ),
  GoRoute(
    path: '/playlist',
    name: "/playlist",
    pageBuilder: (BuildContext context, GoRouterState state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const PlaylistsPage(),
      );
    },
    routes: [
      GoRoute(
        path: ':id',
        name: "/playlist/:id",
        pageBuilder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['id']!;

          return NoTransitionPage(
            key: state.pageKey,
            child: PlaylistPage(playlistId: int.parse(id)),
          );
        },
      ),
    ],
  ),
  GoRoute(
    path: '/artist',
    name: "/artist",
    pageBuilder: (BuildContext context, GoRouterState state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const ArtistsPage(),
      );
    },
    routes: [
      GoRoute(
        path: ':id',
        name: "/artist/:id",
        pageBuilder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['id']!;

          return NoTransitionPage(
            key: state.pageKey,
            child: ArtistPage(artistId: id),
          );
        },
      ),
    ],
  ),
  GoRoute(
    path: '/settings',
    name: "/settings",
    pageBuilder: (BuildContext context, GoRouterState state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const SettingsPage(),
      );
    },
  ),
];

final List<RouteBase> appRoutesWithDesktopPlayerShell = [
  GoRoute(
    path: '/player',
    name: "/player",
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: const PlayerPage(),
      transitionDuration: pageTransitonDuration,
      transitionsBuilder: slideUpTransitionBuilder,
      opaque: false,
    ),
  ),
  GoRoute(
    path: '/queue',
    name: "/queue",
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: const QueueAndHistoryPage(),
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
];
