import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/data/repository/download_album_repository.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/album_viewmodel.dart';
import 'package:melodink_client/features/library/presentation/widgets/album_context_menu.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/manager/download_manager.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class AlbumPage extends riverpod.HookConsumerWidget {
  final int albumId;

  final int? openWithScrollOnSpecificTrackId;

  const AlbumPage({
    super.key,
    required this.albumId,
    this.openWithScrollOnSpecificTrackId,
  });

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final albumContextMenuController = useMemoized(() => MenuController());

    final albumContextMenuKey = useMemoized(() => GlobalKey());

    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

    return ChangeNotifierProvider(
      create: (_) => AlbumViewModel(
        eventBus: ref.read(eventBusProvider),
        audioController: ref.read(audioControllerProvider),
        downloadManager: ref.read(downloadManagerProvider),
        albumRepository: ref.read(albumRepositoryProvider),
        downloadAlbumRepository: ref.read(downloadAlbumRepositoryProvider),
      )..loadAlbum(albumId),
      child: Stack(
        children: [
          AppNavigationHeader(
            title: AppScreenTypeLayoutBuilders(
              mobile: (_) => Text(t.general.album),
            ),
            child: AppScreenTypeLayoutBuilder(
              builder: (context, size) {
                final maxWidth = size == AppScreenTypeLayout.desktop
                    ? 1200
                    : 512;
                final padding = size == AppScreenTypeLayout.desktop
                    ? 24.0
                    : 16.0;

                final separator = size == AppScreenTypeLayout.desktop
                    ? 16.0
                    : 12.0;

                return Consumer<AlbumViewModel>(
                  builder: (context, viewModel, child) {
                    final album = viewModel.album;

                    if (album == null) {
                      return child!;
                    }

                    return AlbumContextMenu(
                      key: albumContextMenuKey,
                      menuController: albumContextMenuController,
                      album: album,
                      customActionsBuilder: (context, _, _) {
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
                              await viewModel.deleteAlbum(context);
                            },
                          ),
                        ];
                      },
                      child: child!,
                    );
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
                        sliver: Consumer<AlbumViewModel>(
                          builder: (context, viewModel, _) {
                            final album = viewModel.album;

                            if (album == null) {
                              return SliverToBoxAdapter();
                            }

                            return StreamBuilder(
                              stream: audioController.playbackState,
                              builder: (context, snapshot) {
                                final isPlaying =
                                    snapshot.data?.playing ?? false;

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
                                          tracks: album.tracks,
                                          artists: album.artists,
                                          playCallback: () => viewModel
                                              .playAlbum(isSameSource, source),
                                          displayPauseButton:
                                              isSameSource && isPlaying,
                                          downloadCallback: () {
                                            if (!viewModel.downloaded) {
                                              viewModel.downloadAlbum();
                                              return;
                                            }
                                            viewModel.removeDownloadedAlbum();
                                          },
                                          downloaded: viewModel.downloaded,
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
                                          tracks: album.tracks,
                                          artists: album.artists,
                                          playCallback: () => viewModel
                                              .playAlbum(isSameSource, source),
                                          displayPauseButton:
                                              isSameSource && isPlaying,
                                          downloadCallback: () {
                                            if (!viewModel.downloaded) {
                                              viewModel.downloadAlbum();
                                              return;
                                            }
                                            viewModel.removeDownloadedAlbum();
                                          },
                                          downloaded: viewModel.downloaded,
                                          contextMenuKey: albumContextMenuKey,
                                          menuController:
                                              albumContextMenuController,
                                        ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SliverContainer(
                        maxWidth: maxWidth,
                        padding: EdgeInsets.only(left: padding, right: padding),
                        sliver: Consumer<AlbumViewModel>(
                          builder: (context, viewModel, _) {
                            if (viewModel.album == null) {
                              return SliverToBoxAdapter();
                            }

                            return StickyDesktopTrackHeader(
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
                            );
                          },
                        ),
                      ),
                      SliverContainer(
                        maxWidth: maxWidth,
                        padding: EdgeInsets.only(left: padding, right: padding),
                        sliver: Consumer<AlbumViewModel>(
                          builder: (context, viewModel, _) {
                            final album = viewModel.album;

                            if (album == null) {
                              return SliverToBoxAdapter();
                            }

                            return TrackList(
                              tracks: album.tracks,
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
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ],
                  ),
                );
              },
            ),
          ),
          Selector<AlbumViewModel, bool>(
            selector: (_, viewModel) => viewModel.isLoading,
            builder: (context, isLoading, _) {
              if (!isLoading) {
                return const SizedBox.shrink();
              }
              return const AppPageLoader();
            },
          ),
        ],
      ),
    );
  }
}
