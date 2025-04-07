import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/providers/create_playlist_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_provider.dart';
import 'package:melodink_client/features/library/presentation/modals/edit_playlist_modal.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class PlaylistContextMenu extends ConsumerWidget {
  const PlaylistContextMenu({
    super.key,
    required this.playlist,
    required this.menuController,
    required this.child,
    this.customActionsBuilder,
  });

  final Playlist playlist;

  final MenuController menuController;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    Playlist playlist,
  )? customActionsBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

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
                    playlistSortedTracksProvider(playlist.id).future,
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
              MenuItemButton(
                leadingIcon: const AdwaitaIcon(
                  AdwaitaIcons.media_playlist_shuffle,
                  size: 20,
                ),
                child: Text(t.actions.randomAddToQueue),
                onPressed: () async {
                  menuController.close();

                  final List<MinimalTrack> tracks = List.from(await ref.read(
                    playlistSortedTracksProvider(playlist.id).future,
                  ));

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

                  EditPlaylistModal.showModal(context, playlist);
                },
              ),
              MenuItemButton(
                leadingIcon: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: AdwaitaIcon(
                    AdwaitaIcons.edit_copy,
                    size: 16,
                  ),
                ),
                child: Text(t.general.duplicate),
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

                  if (!await appConfirm(
                    context,
                    title: t.confirms.title,
                    content: t.confirms.duplicatePlaylist,
                    textOK: t.confirms.confirm,
                  )) {
                    return;
                  }

                  final loadingWidget = OverlayEntry(
                    builder: (context) => AppPageLoader(),
                  );

                  if (context.mounted) {
                    Overlay.of(context, rootOverlay: true)
                        .insert(loadingWidget);
                  }

                  try {
                    final newPlaylist = await ref
                        .read(createPlaylistStreamProvider.notifier)
                        .duplicatePlaylist(playlist.id);

                    loadingWidget.remove();

                    if (!context.mounted) {
                      return;
                    }

                    GoRouter.of(context)
                        .pushReplacement("/playlist/${newPlaylist.id}");

                    AppNotificationManager.of(context).notify(
                      context,
                      message:
                          t.notifications.playlistHaveBeenDuplicated.message(
                        name: playlist.name,
                      ),
                    );
                  } catch (_) {
                    if (context.mounted) {
                      AppNotificationManager.of(context).notify(
                        context,
                        title: t.notifications.somethingWentWrong.title,
                        message: t.notifications.somethingWentWrong.message,
                        type: AppNotificationType.danger,
                      );
                    }

                    loadingWidget.remove();
                  }
                },
              ),
              if (customActionsBuilder != null)
                ...customActionsBuilder!(context, menuController, playlist),
            ],
            controller: menuController,
          ),
          child,
        ],
      ),
    );
  }
}
