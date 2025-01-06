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
import 'package:melodink_client/features/library/domain/providers/delete_playlist_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/playlist_context_menu.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

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

    final tracks =
        ref.watch(playlistSortedTracksProvider(playlistId)).valueOrNull ?? [];

    final playlist = asyncPlaylist.valueOrNull;

    final playlistContextMenuController = useMemoized(() => MenuController());

    final playlistContextMenuKey = useMemoized(() => GlobalKey());

    final isLoading = useState(false);

    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    if (playlist == null) {
      return AppNavigationHeader(
        title: AppScreenTypeLayoutBuilders(
          mobile: (_) => Text(t.general.playlist),
        ),
        child: Container(),
      );
    }

    return Stack(
      children: [
        PlaylistContextMenu(
          key: playlistContextMenuKey,
          menuController: playlistContextMenuController,
          playlist: playlist,
          customActionsBuilder: (context, _, __) {
            return [
              const Divider(height: 8),
              MenuItemButton(
                leadingIcon: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: AdwaitaIcon(
                    AdwaitaIcons.edit_delete,
                    size: 16,
                  ),
                ),
                child: Text(t.general.delete),
                onPressed: () async {
                  playlistContextMenuController.close();

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
                    content: t.confirms.deletePlaylist,
                    textOK: t.confirms.delete,
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
                      message: t.notifications.playlistHaveBeenDeleted.message(
                        name: playlist.name,
                      ),
                    );

                    GoRouter.of(context).pop();
                  } catch (_) {
                    if (context.mounted) {
                      AppNotificationManager.of(context).notify(
                        context,
                        title: t.notifications.somethingWentWrong.title,
                        message: t.notifications.somethingWentWrong.message,
                        type: AppNotificationType.danger,
                      );
                    }
                  }
                  isLoading.value = false;
                },
              ),
            ];
          },
          child: AppNavigationHeader(
            title: AppScreenTypeLayoutBuilders(
              mobile: (_) => Text(t.general.playlist),
            ),
            child: AppScreenTypeLayoutBuilder(
              builder: (context, size) {
                final maxWidth =
                    size == AppScreenTypeLayout.desktop ? 1200 : 512;
                final padding =
                    size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

                final separator =
                    size == AppScreenTypeLayout.desktop ? 16.0 : 12.0;

                return CustomScrollView(
                  key: scrollViewKey,
                  controller: scrollController,
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
                              type: t.general.playlist,
                              imageUrl: playlist.getCompressedCoverUrl(
                                TrackCompressedCoverQuality.high,
                              ),
                              description: playlist.description,
                              tracks: tracks,
                              artists: const [],
                              playCallback: () async {
                                await audioController.loadTracks(
                                  tracks,
                                  source:
                                      "${t.general.playlist} \"${playlist.name}\"",
                                );
                              },
                              downloadCallback: () async {
                                final playlistDownloadNotifier = ref.read(
                                  playlistDownloadNotifierProvider(playlist.id)
                                      .notifier,
                                );

                                if (!playlistDownload.downloaded) {
                                  await playlistDownloadNotifier.download(
                                    shouldCheckDownload: true,
                                  );
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
                              type: t.general.playlist,
                              imageUrl: playlist.getCompressedCoverUrl(
                                TrackCompressedCoverQuality.high,
                              ),
                              tracks: tracks,
                              artists: const [],
                              playCallback: () async {
                                await audioController.loadTracks(
                                  tracks,
                                  source:
                                      "${t.general.playlist} \"${playlist.name}\"",
                                );
                              },
                              downloadCallback: () async {
                                final playlistDownloadNotifier = ref.read(
                                  playlistDownloadNotifierProvider(playlist.id)
                                      .notifier,
                                );

                                if (!playlistDownload.downloaded) {
                                  await playlistDownloadNotifier.download(
                                    shouldCheckDownload: true,
                                  );
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
                      sliver: StickyDesktopTrackHeader(
                        modules: [
                          DesktopTrackModule.title,
                          DesktopTrackModule.album,
                          DesktopTrackModule.lastPlayed,
                          DesktopTrackModule.playedCount,
                          DesktopTrackModule.quality,
                          DesktopTrackModule.duration,
                          DesktopTrackModule.score,
                          DesktopTrackModule.moreActions,
                        ],
                        scrollController: scrollController,
                        scrollViewKey: scrollViewKey,
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
                          DesktopTrackModule.score,
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
                              child: Text(t.actions.removeFromPlaylist),
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

                                try {
                                  await ref
                                      .read(playlistContextMenuNotifierProvider
                                          .notifier)
                                      .setTracks(
                                        playlist,
                                        playlist.tracks.indexed
                                            .where((entry) => entry.$1 != index)
                                            .map((entry) => entry.$2)
                                            .toList(),
                                      );
                                } catch (_) {
                                  if (context.mounted) {
                                    AppNotificationManager.of(context).notify(
                                      context,
                                      title: t.notifications.somethingWentWrong
                                          .title,
                                      message: t.notifications
                                          .somethingWentWrong.message,
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
                                    message: t.notifications
                                        .playlistTrackHaveBeenRemoved
                                        .message(
                                      n: 1,
                                      name: playlist.name,
                                    ));

                                unselect();
                              },
                            ),
                          ];
                        },
                        multiCustomActionsBuilder: (
                          context,
                          menuController,
                          tracks,
                          selectedIndexes,
                          unselect,
                        ) {
                          return [
                            const Divider(height: 8),
                            MenuItemButton(
                              leadingIcon: const AdwaitaIcon(
                                AdwaitaIcons.list_remove,
                                size: 20,
                              ),
                              child: Text(t.actions.removeFromPlaylist),
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

                                try {
                                  await ref
                                      .read(playlistContextMenuNotifierProvider
                                          .notifier)
                                      .setTracks(
                                        playlist,
                                        playlist.tracks.indexed
                                            .where(
                                              (entry) => !selectedIndexes
                                                  .contains(entry.$1),
                                            )
                                            .map((entry) => entry.$2)
                                            .toList(),
                                      );
                                } catch (_) {
                                  if (context.mounted) {
                                    AppNotificationManager.of(context).notify(
                                      context,
                                      title: t.notifications.somethingWentWrong
                                          .title,
                                      message: t.notifications
                                          .somethingWentWrong.message,
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
                                  message: t.notifications
                                      .playlistTrackHaveBeenRemoved
                                      .message(
                                    n: tracks.length,
                                    name: playlist.name,
                                  ),
                                );

                                menuController.close();
                                unselect();
                              },
                            ),
                          ];
                        },
                        source: "${t.general.playlist} \"${playlist.name}\"",
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
        ),
        if (isLoading.value) const AppPageLoader(),
      ],
    );
  }
}
