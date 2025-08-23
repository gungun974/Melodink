import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/animation.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/features/auth/presentation/pages/login_page.dart';
import 'package:melodink_client/features/auth/presentation/pages/register_page.dart';
import 'package:melodink_client/features/auth/presentation/pages/select_server_page.dart';
import 'package:melodink_client/features/home/presentation/pages/home_page.dart';
import 'package:melodink_client/features/library/presentation/pages/album_page.dart';
import 'package:melodink_client/features/library/presentation/pages/albums_page.dart';
import 'package:melodink_client/features/library/presentation/pages/artist_page.dart';
import 'package:melodink_client/features/library/presentation/pages/artists_page.dart';
import 'package:melodink_client/features/library/presentation/pages/edit_playlist_page.dart';
import 'package:melodink_client/features/library/presentation/pages/playlist_page.dart';
import 'package:melodink_client/features/library/presentation/pages/playlists_page.dart';
import 'package:melodink_client/features/player/presentation/pages/player_page.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_and_history_page.dart';
import 'package:melodink_client/features/settings/presentation/pages/settings_page.dart';
import 'package:melodink_client/features/track/presentation/pages/tracks_page.dart';

final routes = [
  AppRoute(
    path: '/',
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      return NoTransitionPage(key: data.pageKey, child: const HomePage());
    },
  ),
  AppRoute(
    path: '/track',
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      return NoTransitionPage(key: data.pageKey, child: const TracksPage());
    },
  ),
  AppRoute(
    path: '/playlist',
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      return NoTransitionPage(key: data.pageKey, child: const PlaylistsPage());
    },
  ),
  AppRoute(
    path: "/playlist/:id",
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      final id = data.parameters['id']!;

      return NoTransitionPage(
        key: data.pageKey,
        child: PlaylistPage(playlistId: int.parse(id)),
      );
    },
  ),
  AppRoute(
    path: "/playlist/:id/edit",
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      final id = data.parameters['id']!;

      return NoTransitionPage(
        key: data.pageKey,
        child: PlaylistPageEdit(playlistId: int.parse(id)),
      );
    },
  ),
  AppRoute(
    path: '/album',
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      return NoTransitionPage(key: data.pageKey, child: const AlbumsPage());
    },
  ),
  AppRoute(
    path: '/album/:id',
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      final id = data.parameters['id']!;

      final extraData = data.extra as Map<String, dynamic>?;

      final int? trackId =
          extraData?['openWithScrollOnSpecificTrackId'] as int?;

      return NoTransitionPage(
        key: data.pageKey,
        child: AlbumPage(
          albumId: int.parse(id),
          openWithScrollOnSpecificTrackId: trackId,
        ),
      );
    },
  ),
  AppRoute(
    path: '/artist',
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      return NoTransitionPage(key: data.pageKey, child: const ArtistsPage());
    },
  ),
  AppRoute(
    path: "/artist/:id",
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      final id = data.parameters['id']!;

      return NoTransitionPage(
        key: data.pageKey,
        child: ArtistPage(artistId: int.parse(id)),
      );
    },
  ),
  AppRoute(
    path: '/settings',
    viewType: AppRouteViewType.sideBarPage,
    pageBuilder: (context, data) {
      return NoTransitionPage(key: data.pageKey, child: const SettingsPage());
    },
  ),
  AppRoute(
    path: '/player',
    viewType: AppRouteViewType.playerBarPage,
    pageBuilder: (context, data) => CustomTransitionPage<void>(
      key: data.pageKey,
      child: const PlayerPage(),
      transitionDuration: pageTransitonDuration,
      transitionsBuilder: slideUpTransitionBuilder,
      opaque: false,
    ),
  ),
  AppRoute(
    path: '/queue',
    viewType: AppRouteViewType.playerBarPage,
    pageBuilder: (context, data) => CustomTransitionPage<void>(
      key: data.pageKey,
      child: const QueueAndHistoryPage(),
      transitionDuration: pageTransitonDuration,
      transitionsBuilder: slideUpTransitionBuilder,
    ),
  ),
  AppRoute(
    path: '/auth/serverSetup',
    viewType: AppRouteViewType.fullPage,
    pageBuilder: (context, data) {
      return MaterialPage(key: data.pageKey, child: const SelectServerPage());
    },
  ),
  AppRoute(
    path: '/auth/login',
    viewType: AppRouteViewType.fullPage,
    pageBuilder: (context, data) {
      return MaterialPage(key: data.pageKey, child: const LoginPage());
    },
  ),
  AppRoute(
    path: '/auth/register',
    viewType: AppRouteViewType.fullPage,
    pageBuilder: (context, data) {
      return MaterialPage(key: data.pageKey, child: const RegisterPage());
    },
  ),
];
