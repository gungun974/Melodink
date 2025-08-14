import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/album_provider.dart';
import 'package:melodink_client/features/library/domain/providers/delete_album_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/album_context_menu.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class AlbumPage extends HookConsumerWidget {
  final int albumId;

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

    final tracks =
        ref.watch(albumSortedTracksProvider(albumId)).valueOrNull ?? [];

    final album = asyncAlbum.valueOrNull;

    final albumContextMenuController = useMemoized(() => MenuController());

    final albumContextMenuKey = useMemoized(() => GlobalKey());

    final isLoading = useState(false);

    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

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

              return AlbumContextMenu(
                key: albumContextMenuKey,
                menuController: albumContextMenuController,
                album: album,
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

                        if (!await appConfirm(
                          context,
                          title: t.confirms.title,
                          content: t.confirms.deleteAlbum,
                          textOK: t.confirms.delete,
                          isDangerous: true,
                        )) {
                          return;
                        }

                        isLoading.value = true;

                        try {
                          await ref
                              .read(deleteAlbumStreamProvider.notifier)
                              .deleteAlbum(album.id);

                          isLoading.value = false;

                          if (!context.mounted) {
                            return;
                          }

                          AppNotificationManager.of(context).notify(
                            context,
                            message:
                                t.notifications.albumHaveBeenDeleted.message(
                              name: album.name,
                            ),
                          );

                          GoRouter.of(context).pop();
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
                        }
                        isLoading.value = false;
                      },
                    ),
                  ];
                },
                child: CustomScrollView(
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
                      sliver: StreamBuilder(
                          stream: audioController.playbackState,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data?.playing ?? false;

                            final source =
                                "${t.general.album} \"${album.name}\"";

                            final isSameSource =
                                audioController.playerTracksFrom.value ==
                                    source;

                            return SliverToBoxAdapter(
                              child: size == AppScreenTypeLayout.desktop
                                  ? DesktopPlaylistHeader(
                                      name: album.name,
                                      type: t.general.album,
                                      imageUrl: album.getCompressedCoverUrl(
                                        TrackCompressedCoverQuality.high,
                                      ),
                                      year: album.getYear(),
                                      description: "",
                                      tracks: tracks,
                                      artists: album.artists,
                                      playCallback: () async {
                                        if (!isSameSource) {
                                          await audioController.loadTracks(
                                            tracks,
                                            source: source,
                                          );
                                          return;
                                        }

                                        if (isPlaying) {
                                          await audioController.pause();
                                          return;
                                        }

                                        await audioController.play();
                                      },
                                      displayPauseButton:
                                          isSameSource && isPlaying,
                                      downloadCallback: () async {
                                        final albumDownloadNotifier = ref.read(
                                          albumDownloadNotifierProvider(
                                                  album.id)
                                              .notifier,
                                        );

                                        if (!albumDownload.downloaded) {
                                          await albumDownloadNotifier.download(
                                            shouldCheckDownload: true,
                                          );
                                        } else {
                                          await albumDownloadNotifier
                                              .deleteDownloaded();
                                        }
                                      },
                                      downloaded: albumDownload.downloaded,
                                      contextMenuKey: albumContextMenuKey,
                                      menuController:
                                          albumContextMenuController,
                                    )
                                  : MobilePlaylistHeader(
                                      name: album.name,
                                      type: t.general.album,
                                      imageUrl: album.getCompressedCoverUrl(
                                        TrackCompressedCoverQuality.high,
                                      ),
                                      year: album.getYear(),
                                      tracks: tracks,
                                      artists: album.artists,
                                      playCallback: () async {
                                        if (!isSameSource) {
                                          await audioController.loadTracks(
                                            tracks,
                                            source: source,
                                          );
                                          return;
                                        }

                                        if (isPlaying) {
                                          await audioController.pause();
                                          return;
                                        }

                                        await audioController.play();
                                      },
                                      displayPauseButton:
                                          isSameSource && isPlaying,
                                      downloadCallback: () async {
                                        final albumDownloadNotifier = ref.read(
                                          albumDownloadNotifierProvider(
                                                  album.id)
                                              .notifier,
                                        );

                                        if (!albumDownload.downloaded) {
                                          await albumDownloadNotifier.download(
                                            shouldCheckDownload: true,
                                          );
                                        } else {
                                          await albumDownloadNotifier
                                              .deleteDownloaded();
                                        }
                                      },
                                      downloaded: albumDownload.downloaded,
                                      contextMenuKey: albumContextMenuKey,
                                      menuController:
                                          albumContextMenuController,
                                    ),
                            );
                          }),
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
                        scrollToTrackIdOnMounted:
                            openWithScrollOnSpecificTrackId,
                        source: "${t.general.album} \"${album.name}\"",
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (isLoading.value) const AppPageLoader(),
      ],
    );
  }
}
