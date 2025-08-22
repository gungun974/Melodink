import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/presentation/modals/create_playlist_modal.dart';
import 'package:melodink_client/features/library/presentation/modals/edit_album_modal.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/playlists_context_menu_viewmodel.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class AlbumContextMenu extends StatelessWidget {
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
  )?
  customActionsBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    return AutoCloseContextMenuOnScroll(
      menuController: menuController,
      child: Stack(
        children: [
          MenuAnchor(
            clipBehavior: Clip.antiAlias,
            menuChildren: [
              ChangeNotifierProvider(
                create: (context) => PlaylistsContextMenuViewModel(
                  eventBus: context.read(),
                  playlistRepository: context.read(),
                )..loadPlaylists(),
                child: Consumer<PlaylistsContextMenuViewModel>(
                  builder: (context, viewModel, _) {
                    return SubmenuButton(
                      leadingIcon: const AdwaitaIcon(
                        AdwaitaIcons.playlist2,
                        size: 20,
                      ),
                      menuChildren: [
                        MenuItemButton(
                          child: Text(t.actions.newPlaylist),
                          onPressed: () async {
                            menuController.close();

                            if (!context.mounted) {
                              return;
                            }

                            CreatePlaylistModal.showModal(
                              context,
                              tracks: album.tracks,
                              pushRouteToNewPlaylist: true,
                            );
                          },
                        ),
                        const Divider(height: 0),
                        ...viewModel.playlists.map((playlist) {
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

                              final tracks = album.tracks;

                              try {
                                await viewModel.addTracks(playlist, tracks);
                              } catch (_) {
                                if (context.mounted) {
                                  AppNotificationManager.of(context).notify(
                                    context,
                                    title: t
                                        .notifications
                                        .somethingWentWrong
                                        .title,
                                    message: t
                                        .notifications
                                        .somethingWentWrong
                                        .message,
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
                                    .notifications
                                    .playlistTrackHaveBeenAdded
                                    .message(
                                      n: tracks.length,
                                      name: playlist.name,
                                    ),
                              );
                            },
                          );
                        }),
                      ],
                      child: Text(t.actions.addToPlaylist),
                    );
                  },
                ),
              ),
              MenuItemButton(
                leadingIcon: const AdwaitaIcon(AdwaitaIcons.playlist, size: 20),
                child: Text(t.actions.addToQueue),
                onPressed: () async {
                  menuController.close();

                  final tracks = album.tracks;

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
              MenuItemButton(
                leadingIcon: const AdwaitaIcon(
                  AdwaitaIcons.media_playlist_shuffle,
                  size: 20,
                ),
                child: Text(t.actions.randomAddToQueue),
                onPressed: () async {
                  menuController.close();

                  final List<Track> tracks = List.from(album.tracks);

                  tracks.shuffle();

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
              const Divider(height: 8),
              MenuItemButton(
                leadingIcon: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: AdwaitaIcon(AdwaitaIcons.edit, size: 16),
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
