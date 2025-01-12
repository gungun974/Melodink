import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/providers/album_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/library/presentation/modals/create_playlist_modal.dart';
import 'package:melodink_client/features/library/presentation/modals/edit_album_modal.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class AlbumContextMenu extends ConsumerWidget {
  const AlbumContextMenu({
    super.key,
    required this.album,
    required this.menuController,
    required this.child,
    this.customActionsBuilder,
  });

  final Album album;

  final MenuController menuController;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    Album album,
  )? customActionsBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final asyncPlaylists = ref.watch(playlistContextMenuNotifierProvider);

    return AutoCloseContextMenuOnScroll(
      menuController: menuController,
      child: Stack(
        children: [
          MenuAnchor(
            clipBehavior: Clip.antiAlias,
            menuChildren: [
              MenuItemButton(
                leadingIcon: const AdwaitaIcon(
                  AdwaitaIcons.playlist,
                  size: 20,
                ),
                child: Text(t.actions.addToQueue),
                onPressed: () async {
                  menuController.close();

                  final tracks = await ref.read(
                    albumSortedTracksProvider(album.id).future,
                  );

                  audioController.addTracksToQueue(tracks);

                  if (!context.mounted) {
                    return;
                  }

                  AppNotificationManager.of(context).notify(
                    context,
                    message: t.notifications.haveBeenAddedToQueue.message(
                      n: tracks.length,
                    ),
                  );
                },
              ),
              SubmenuButton(
                leadingIcon: const AdwaitaIcon(
                  AdwaitaIcons.playlist2,
                  size: 20,
                ),
                menuChildren: [
                  MenuItemButton(
                    child: Text(t.actions.newPlaylist),
                    onPressed: () async {
                      menuController.close();

                      final tracks = await ref.read(
                        albumSortedTracksProvider(album.id).future,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      CreatePlaylistModal.showModal(
                        context,
                        tracks: tracks,
                        pushRouteToNewPlaylist: true,
                      );
                    },
                  ),
                  const Divider(height: 0),
                  ...switch (asyncPlaylists) {
                    AsyncData(:final value) => value.map((playlist) {
                        return MenuItemButton(
                          child: Text(playlist.name),
                          onPressed: () async {
                            menuController.close();

                            if (!NetworkInfo().isServerRecheable()) {
                              AppNotificationManager.of(context).notify(
                                context,
                                title: t.notifications.offline.title,
                                message: t.notifications.offline.message,
                                type: AppNotificationType.danger,
                              );
                              return;
                            }

                            final tracks = await ref.read(
                              albumSortedTracksProvider(album.id).future,
                            );

                            try {
                              await ref
                                  .read(playlistContextMenuNotifierProvider
                                      .notifier)
                                  .addTracks(
                                    playlist,
                                    tracks,
                                  );
                            } catch (_) {
                              if (context.mounted) {
                                AppNotificationManager.of(context).notify(
                                  context,
                                  title:
                                      t.notifications.somethingWentWrong.title,
                                  message: t
                                      .notifications.somethingWentWrong.message,
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
                              message: t
                                  .notifications.playlistTrackHaveBeenAdded
                                  .message(
                                n: tracks.length,
                                name: playlist.name,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    _ => const [],
                  },
                ],
                child: Text(t.actions.addToPlaylist),
              ),
              const Divider(height: 8),
              MenuItemButton(
                leadingIcon: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: AdwaitaIcon(
                    AdwaitaIcons.edit,
                    size: 16,
                  ),
                ),
                child: Text(t.general.edit),
                onPressed: () {
                  menuController.close();

                  if (!NetworkInfo().isServerRecheable()) {
                    AppNotificationManager.of(context).notify(
                      context,
                      title: t.notifications.offline.title,
                      message: t.notifications.offline.message,
                      type: AppNotificationType.danger,
                    );
                    return;
                  }

                  EditAlbumModal.showModal(context, album);
                },
              ),
              if (customActionsBuilder != null)
                ...customActionsBuilder!(context, menuController, album),
            ],
            controller: menuController,
          ),
          child,
        ],
      ),
    );
  }
}
