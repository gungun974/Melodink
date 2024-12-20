import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';

class MultiTracksContextMenu extends ConsumerWidget {
  const MultiTracksContextMenu({
    super.key,
    required this.tracks,
    required this.menuController,
    required this.child,
    this.customActionsBuilder,
  });

  final List<MinimalTrack> tracks;

  final MenuController menuController;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    List<MinimalTrack> track,
  )? customActionsBuilder;

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
                  onPressed: () async {
                    if (!NetworkInfo().isServerRecheable()) {
                      AppNotificationManager.of(context).notify(
                        context,
                        title: "Offline",
                        message:
                            "You can't perform this action while being offline.",
                        type: AppNotificationType.danger,
                      );
                      return;
                    }

                    try {
                      await ref
                          .read(playlistContextMenuNotifierProvider.notifier)
                          .addTracks(
                            playlist,
                            tracks,
                          );
                    } catch (_) {
                      if (context.mounted) {
                        AppNotificationManager.of(context).notify(
                          context,
                          title: "Error",
                          message: "Something went wrong",
                          type: AppNotificationType.danger,
                        );
                      }

                      rethrow;
                    }

                    if (!context.mounted) {
                      return;
                    }

                    AppNotificationManager.of(context).notify(
                      context,
                      message:
                          "${tracks.length} track${tracks.length > 1 ? 's' : ''} have been added to playlist \"${playlist.name}\".",
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

            AppNotificationManager.of(context).notify(
              context,
              message:
                  "${tracks.length} track${tracks.length > 1 ? 's' : ''} have been added to the queue.",
            );
          },
        ),
        if (customActionsBuilder != null)
          ...customActionsBuilder!(context, menuController, tracks),
      ],
      controller: menuController,
      child: child,
    );
  }
}
