import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/album_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/library/presentation/modals/edit_album_modal.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class AlbumPage extends HookConsumerWidget {
  final String albumId;

  final int? openWithScrollOnSpecificTrackId;

  const AlbumPage({
    super.key,
    required this.albumId,
    this.openWithScrollOnSpecificTrackId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final asyncAlbum = ref.watch(albumByIdProvider(albumId));
    final albumDownload = ref.watch(albumDownloadNotifierProvider(albumId));
    final asyncPlaylists = ref.watch(playlistContextMenuNotifierProvider);

    final tracks = ref.watch(albumSortedTracksProvider(albumId));

    final album = asyncAlbum.valueOrNull;

    final albumContextMenuController = useMemoized(() => MenuController());

    final albumContextMenuKey = useMemoized(() => GlobalKey());

    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    if (album == null) {
      return AppNavigationHeader(
        title: AppScreenTypeLayoutBuilders(
          mobile: (_) => Text(t.general.album),
        ),
        child: Container(),
      );
    }

    return Stack(
      children: [
        MenuAnchor(
          key: albumContextMenuKey,
          clipBehavior: Clip.antiAlias,
          menuChildren: [
            MenuItemButton(
              leadingIcon: const AdwaitaIcon(
                AdwaitaIcons.playlist,
                size: 20,
              ),
              child: Text(t.actions.addToQueue),
              onPressed: () {
                albumContextMenuController.close();

                audioController.addTracksToQueue(album.tracks);

                AppNotificationManager.of(context).notify(
                  context,
                  message: t.notifications.haveBeenAddedToQueue.message(
                    n: album.tracks.length,
                  ),
                );
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
                      onPressed: () async {
                        albumContextMenuController.close();

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
                              .read(
                                  playlistContextMenuNotifierProvider.notifier)
                              .addTracks(
                                playlist,
                                tracks,
                              );
                        } catch (_) {
                          if (context.mounted) {
                            AppNotificationManager.of(context).notify(
                              context,
                              title: t.notifications.somethingWentWrong.title,
                              message:
                                  t.notifications.somethingWentWrong.message,
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
                          message: t.notifications.playlistTrackHaveBeenAdded
                              .message(
                            n: album.tracks.length,
                            name: playlist.name,
                          ),
                        );
                      },
                    );
                  }).toList(),
                _ => const [],
              },
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
                albumContextMenuController.close();

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
          ],
          controller: albumContextMenuController,
        ),
        AppNavigationHeader(
          title: AppScreenTypeLayoutBuilders(
            mobile: (_) => Text(t.general.album),
          ),
          child: AppScreenTypeLayoutBuilder(
            builder: (context, size) {
              final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
              final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

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
                            name: album.name,
                            type: t.general.album,
                            imageUrl: album.getCompressedCoverUrl(
                              TrackCompressedCoverQuality.high,
                            ),
                            description: "",
                            tracks: tracks,
                            artists: album.albumArtists,
                            playCallback: () async {
                              await audioController.loadTracks(
                                tracks,
                                source: "${t.general.album} \"${album.name}\"",
                              );
                            },
                            downloadCallback: () async {
                              final albumDownloadNotifier = ref.read(
                                albumDownloadNotifierProvider(album.id)
                                    .notifier,
                              );

                              if (!albumDownload.downloaded) {
                                await albumDownloadNotifier.download(
                                  shouldCheckDownload: true,
                                );
                              } else {
                                await albumDownloadNotifier.deleteDownloaded();
                              }
                            },
                            downloaded: albumDownload.downloaded,
                            contextMenuKey: albumContextMenuKey,
                            menuController: albumContextMenuController,
                          )
                        : MobilePlaylistHeader(
                            name: album.name,
                            type: t.general.album,
                            imageUrl: album.getCompressedCoverUrl(
                              TrackCompressedCoverQuality.high,
                            ),
                            tracks: tracks,
                            artists: album.albumArtists,
                            playCallback: () async {
                              await audioController.loadTracks(
                                tracks,
                                source: "${t.general.album} \"${album.name}\"",
                              );
                            },
                            downloadCallback: () async {
                              final albumDownloadNotifier = ref.read(
                                albumDownloadNotifierProvider(album.id)
                                    .notifier,
                              );

                              if (!albumDownload.downloaded) {
                                await albumDownloadNotifier.download(
                                  shouldCheckDownload: true,
                                );
                              } else {
                                await albumDownloadNotifier.deleteDownloaded();
                              }
                            },
                            downloaded: albumDownload.downloaded,
                            contextMenuKey: albumContextMenuKey,
                            menuController: albumContextMenuController,
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
                      showImage: false,
                      modules: const [
                        DesktopTrackModule.title,
                        DesktopTrackModule.lastPlayed,
                        DesktopTrackModule.playedCount,
                        DesktopTrackModule.quality,
                        DesktopTrackModule.duration,
                        DesktopTrackModule.score,
                        DesktopTrackModule.moreActions,
                      ],
                      scrollController: scrollController,
                      scrollToTrackIdOnMounted: openWithScrollOnSpecificTrackId,
                      source: "${t.general.album} \"${album.name}\"",
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 8),
                  ),
                ],
              );
            },
          ),
        )
      ],
    );
  }
}
