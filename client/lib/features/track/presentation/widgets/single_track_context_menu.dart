import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class SingleTrackContextMenu extends ConsumerWidget {
  const SingleTrackContextMenu({
    super.key,
    required this.track,
    required this.menuController,
    required this.child,
    this.customActionsBuilder,
  });

  final MinimalTrack track;

  final MenuController menuController;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    MinimalTrack track,
  )? customActionsBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final asyncPlaylists = ref.watch(playlistContextMenuNotifierProvider);

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.playlist,
            size: 20,
          ),
          child: const Text("Add to queue"),
          onPressed: () {
            audioController.addTrackToQueue(track);
            menuController.close();
          },
        ),
        SubmenuButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.playlist2,
            size: 20,
          ),
          menuChildren: switch (asyncPlaylists) {
            AsyncData(:final value) => value.map((playlist) {
                return MenuItemButton(
                  child: Text(playlist.name),
                  onPressed: () {
                    ref
                        .read(playlistContextMenuNotifierProvider.notifier)
                        .addTracks(
                      playlist,
                      [track],
                    );
                    menuController.close();
                  },
                );
              }).toList(),
            _ => const [],
          },
          child: const Text("Add to playlist"),
        ),
        const Divider(height: 8),
        MenuItemButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.media_optical,
            size: 20,
          ),
          child: const Text("Go to album"),
          onPressed: () {
            while (
                GoRouter.of(context).location?.startsWith("/queue") ?? true) {
              GoRouter.of(context).pop();
            }

            while (
                GoRouter.of(context).location?.startsWith("/player") ?? true) {
              GoRouter.of(context).pop();
            }

            GoRouter.of(context).push("/album/${track.albumId}");
          },
        ),
        if (track.artists.length == 1)
          MenuItemButton(
            leadingIcon: const AdwaitaIcon(
              AdwaitaIcons.person2,
              size: 20,
            ),
            child: const Text("Go to artist"),
            onPressed: () {
              while (
                  GoRouter.of(context).location?.startsWith("/queue") ?? true) {
                GoRouter.of(context).pop();
              }

              while (GoRouter.of(context).location?.startsWith("/player") ??
                  true) {
                GoRouter.of(context).pop();
              }

              GoRouter.of(context).push("/artist/${track.artists.first.id}");
            },
          ),
        if (track.artists.length > 1)
          SubmenuButton(
            leadingIcon: const AdwaitaIcon(
              AdwaitaIcons.person2,
              size: 20,
            ),
            menuChildren: track.artists.map(
              (artist) {
                return MenuItemButton(
                  leadingIcon: const AdwaitaIcon(
                    AdwaitaIcons.person2,
                    size: 20,
                  ),
                  child: Text(artist.name),
                  onPressed: () {
                    while (
                        GoRouter.of(context).location?.startsWith("/queue") ??
                            true) {
                      GoRouter.of(context).pop();
                    }

                    while (
                        GoRouter.of(context).location?.startsWith("/player") ??
                            true) {
                      GoRouter.of(context).pop();
                    }

                    GoRouter.of(context).push("/artist/${artist.id}");
                  },
                );
              },
            ).toList(),
            child: const Text("Go to artist"),
          ),
        if (customActionsBuilder != null)
          ...customActionsBuilder!(context, menuController, track),
      ],
      controller: menuController,
      child: child,
    );
  }
}