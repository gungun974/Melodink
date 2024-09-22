import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class MultiTracksContextMenu extends ConsumerWidget {
  const MultiTracksContextMenu({
    super.key,
    required this.tracks,
    required this.menuController,
    required this.child,
  });

  final List<MinimalTrack> tracks;

  final MenuController menuController;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final asyncPlaylists = ref.watch(playlistContextMenuNotifierProvider);

    return MenuAnchor(
      menuChildren: [
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
                          tracks,
                        );
                  },
                );
              }).toList(),
            _ => const [],
          },
          child: const Text("Add to playlist"),
        ),
        MenuItemButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.playlist,
            size: 20,
          ),
          child: const Text("Add tracks to queue"),
          onPressed: () {
            audioController.addTracksToQueue(tracks);
          },
        ),
      ],
      controller: menuController,
      child: child,
    );
  }
}
