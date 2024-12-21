import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/create_playlist_provider.dart';
import 'package:melodink_client/features/library/domain/providers/delete_playlist_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_provider.dart';
import 'package:melodink_client/features/library/presentation/modals/edit_playlist_modal.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';

class PlaylistPage extends HookConsumerWidget {
  final int playlistId;

  const PlaylistPage({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final asyncPlaylist = ref.watch(playlistByIdProvider(playlistId));
    final playlistDownload =
        ref.watch(playlistDownloadNotifierProvider(playlistId));

    final tracks = ref.watch(playlistSortedTracksProvider(playlistId));

    final playlist = asyncPlaylist.valueOrNull;

    final playlistContextMenuController = useMemoized(() => MenuController());

    final playlistContextMenuKey = useMemoized(() => GlobalKey());

    final isLoading = useState(false);

    if (playlist == null) {
      return AppNavigationHeader(
        title: AppScreenTypeLayoutBuilders(
          mobile: (_) => const Text("Playlist"),
        ),
        child: Container(),
      );
    }

    return Stack(
      children: [
        MenuAnchor(
          key: playlistContextMenuKey,
          menuChildren: [
            MenuItemButton(
              leadingIcon: const AdwaitaIcon(
                AdwaitaIcons.playlist,
                size: 20,
              ),
              child: const Text("Add to queue"),
              onPressed: () {
                audioController.addTracksToQueue(playlist.tracks);
                playlistContextMenuController.close();

                AppNotificationManager.of(context).notify(
                  context,
                  message:
                      "${playlist.tracks.length} track${playlist.tracks.length > 1 ? 's' : ''} have been added to the queue.",
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
              child: const Text("Edit"),
              onPressed: () {
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
              child: const Text("Duplicate"),
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

                if (!await appConfirm(
                  context,
                  title: "Confirm",
                  content: "Would you like to duplicate this playlist ?'",
                  textOK: "Confirm",
                )) {
                  return;
                }

                isLoading.value = true;

                try {
                  final newPlaylist = await ref
                      .read(createPlaylistStreamProvider.notifier)
                      .duplicatePlaylist(playlist.id);

                  isLoading.value = false;

                  if (!context.mounted) {
                    return;
                  }

                  GoRouter.of(context)
                      .pushReplacement("/playlist/${newPlaylist.id}");

                  AppNotificationManager.of(context).notify(
                    context,
                    message:
                        "The playlist \"${playlist.name}\" has been successfully duplicated.",
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
                }
                isLoading.value = false;
              },
            ),
            const Divider(height: 8),
            MenuItemButton(
              leadingIcon: const Padding(
                padding: EdgeInsets.all(2.0),
                child: AdwaitaIcon(
                  AdwaitaIcons.edit_delete,
                  size: 16,
                ),
              ),
              child: const Text("Delete"),
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

                if (!await appConfirm(
                  context,
                  title: "Confirm",
                  content: "Would you like to delete this playlist ?'",
                  textOK: "DELETE",
                  isDangerous: true,
                )) {
                  return;
                }

                isLoading.value = true;

                try {
                  await ref
                      .read(deletePlaylistStreamProvider.notifier)
                      .deletePlaylist(playlist.id);

                  isLoading.value = false;

                  if (!context.mounted) {
                    return;
                  }

                  AppNotificationManager.of(context).notify(
                    context,
                    message:
                        "The playlist \"${playlist.name}\" has been successfully deleted.",
                  );

                  GoRouter.of(context).pop();
                } catch (_) {
                  if (context.mounted) {
                    AppNotificationManager.of(context).notify(
                      context,
                      title: "Error",
                      message: "Something went wrong",
                      type: AppNotificationType.danger,
                    );
                  }
                }
                isLoading.value = false;
              },
            ),
          ],
          controller: playlistContextMenuController,
        ),
        AppNavigationHeader(
          title: AppScreenTypeLayoutBuilders(
            mobile: (_) => const Text("Playlist"),
          ),
          child: AppScreenTypeLayoutBuilder(
            builder: (context, size) {
              final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
              final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

              final separator =
                  size == AppScreenTypeLayout.desktop ? 16.0 : 12.0;

              return CustomScrollView(
                slivers: [
                  SliverContainer(
                    maxWidth: maxWidth,
                    padding: EdgeInsets.only(
                      left: padding,
                      right: padding,
                      top: padding,
                      bottom: separator,
                    ),
                    sliver: size == AppScreenTypeLayout.desktop
                        ? DesktopPlaylistHeader(
                            name: playlist.name,
                            type: "Playlist",
                            imageUrl: playlist.getCompressedCoverUrl(
                              TrackCompressedCoverQuality.high,
                            ),
                            description: playlist.description,
                            tracks: tracks,
                            artists: const [],
                            playCallback: () async {
                              await audioController.loadTracks(
                                tracks,
                                source: "Playlist \"${playlist.name}\"",
                              );
                            },
                            downloadCallback: () async {
                              final playlistDownloadNotifier = ref.read(
                                playlistDownloadNotifierProvider(playlist.id)
                                    .notifier,
                              );

                              if (!playlistDownload.downloaded) {
                                await playlistDownloadNotifier.download();
                              } else {
                                await playlistDownloadNotifier
                                    .deleteDownloaded();
                              }
                            },
                            downloaded: playlistDownload.downloaded,
                            contextMenuKey: playlistContextMenuKey,
                            menuController: playlistContextMenuController,
                          )
                        : MobilePlaylistHeader(
                            name: playlist.name,
                            type: "Playlist",
                            imageUrl: playlist.getCompressedCoverUrl(
                              TrackCompressedCoverQuality.high,
                            ),
                            tracks: tracks,
                            artists: const [],
                            playCallback: () async {
                              await audioController.loadTracks(
                                tracks,
                                source: "Playlist \"${playlist.name}\"",
                              );
                            },
                            downloadCallback: () async {
                              final playlistDownloadNotifier = ref.read(
                                playlistDownloadNotifierProvider(playlist.id)
                                    .notifier,
                              );

                              if (!playlistDownload.downloaded) {
                                await playlistDownloadNotifier.download();
                              } else {
                                await playlistDownloadNotifier
                                    .deleteDownloaded();
                              }
                            },
                            downloaded: playlistDownload.downloaded,
                            contextMenuKey: playlistContextMenuKey,
                            menuController: playlistContextMenuController,
                          ),
                  ),
                  SliverContainer(
                    maxWidth: maxWidth,
                    padding: EdgeInsets.only(
                      left: padding,
                      right: padding,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.03),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                              8,
                            ),
                          ),
                        ),
                        child: size == AppScreenTypeLayout.desktop
                            ? const DesktopTrackHeader(
                                modules: [
                                  DesktopTrackModule.title,
                                  DesktopTrackModule.album,
                                  DesktopTrackModule.lastPlayed,
                                  DesktopTrackModule.playedCount,
                                  DesktopTrackModule.quality,
                                  DesktopTrackModule.duration,
                                  DesktopTrackModule.moreActions,
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  SliverContainer(
                    maxWidth: maxWidth,
                    padding: EdgeInsets.only(
                      left: padding,
                      right: padding,
                    ),
                    sliver: TrackList(
                      tracks: tracks,
                      size: size,
                      showTrackIndex: false,
                      modules: const [
                        DesktopTrackModule.title,
                        DesktopTrackModule.album,
                        DesktopTrackModule.lastPlayed,
                        DesktopTrackModule.playedCount,
                        DesktopTrackModule.quality,
                        DesktopTrackModule.duration,
                        DesktopTrackModule.moreActions,
                      ],
                      singleCustomActionsBuilder: (
                        context,
                        menuController,
                        tracks,
                        index,
                        unselect,
                      ) {
                        return [
                          const Divider(height: 8),
                          MenuItemButton(
                            leadingIcon: const AdwaitaIcon(
                              AdwaitaIcons.list_remove,
                              size: 20,
                            ),
                            child: const Text("Remove from this playlist"),
                            onPressed: () async {
                              menuController.close();

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
                                    .read(playlistContextMenuNotifierProvider
                                        .notifier)
                                    .removeTracks(
                                      playlist,
                                      index,
                                      index,
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
                                    "track have been removed from playlist \"${playlist.name}\".",
                              );

                              unselect();
                            },
                          ),
                        ];
                      },
                      multiCustomActionsBuilder: (
                        context,
                        menuController,
                        tracks,
                        startIndex,
                        endIndex,
                        unselect,
                      ) {
                        return [
                          const Divider(height: 8),
                          MenuItemButton(
                            leadingIcon: const AdwaitaIcon(
                              AdwaitaIcons.list_remove,
                              size: 20,
                            ),
                            child: const Text("Remove from this playlist"),
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
                                    .read(playlistContextMenuNotifierProvider
                                        .notifier)
                                    .removeTracks(
                                      playlist,
                                      startIndex,
                                      endIndex,
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
                                    "${tracks.length} track${tracks.length > 1 ? 's' : ''} have been removed from playlist \"${playlist.name}\".",
                              );

                              menuController.close();
                              unselect();
                            },
                          ),
                        ];
                      },
                      source: "Playlist \"${playlist.name}\"",
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 8),
                  ),
                ],
              );
            },
          ),
        ),
        if (isLoading.value) const AppPageLoader(),
      ],
    );
  }
}
