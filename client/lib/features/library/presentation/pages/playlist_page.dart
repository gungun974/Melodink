import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/playlist_viewmodel.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/playlist_context_menu.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class PlaylistPage extends HookWidget {
  final int playlistId;

  const PlaylistPage({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    final playlistContextMenuController = useMemoized(() => MenuController());

    final playlistContextMenuKey = useMemoized(() => GlobalKey());

    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

    return ChangeNotifierProvider(
      create: (context) => PlaylistViewModel(
        eventBus: context.read(),
        audioController: context.read(),
        downloadManager: context.read(),
        playlistRepository: context.read(),
        downloadPlaylistRepository: context.read(),
      )..loadPlaylist(playlistId),
      child: Stack(
        children: [
          AppNavigationHeader(
            title: AppScreenTypeLayoutBuilders(
              mobile: (_) => Text(t.general.playlist),
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

                return Consumer<PlaylistViewModel>(
                  builder: (context, viewModel, child) {
                    final playlist = viewModel.playlist;

                    if (playlist == null) {
                      return child!;
                    }

                    return PlaylistContextMenu(
                      key: playlistContextMenuKey,
                      menuController: playlistContextMenuController,
                      playlist: playlist,
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
                              playlistContextMenuController.close();
                              await viewModel.deletePlaylist(context);
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
                        sliver: Consumer<PlaylistViewModel>(
                          builder: (context, viewModel, _) {
                            final playlist = viewModel.playlist;

                            if (playlist == null) {
                              return SliverToBoxAdapter();
                            }

                            return StreamBuilder(
                              stream: audioController.playbackState,
                              builder: (context, snapshot) {
                                final isPlaying =
                                    snapshot.data?.playing ?? false;

                                final source =
                                    "${t.general.playlist} \"${playlist.name}\"";

                                final isSameSource =
                                    audioController.playerTracksFrom.value ==
                                    source;
                                return SliverToBoxAdapter(
                                  child: size == AppScreenTypeLayout.desktop
                                      ? DesktopPlaylistHeader(
                                          name: playlist.name,
                                          type: t.general.playlist,
                                          imageUrl: playlist
                                              .getCompressedCoverUrl(
                                                TrackCompressedCoverQuality
                                                    .high,
                                              ),
                                          year: "",
                                          description: playlist.description,
                                          tracks: playlist.tracks,
                                          artists: const [],
                                          playCallback: () =>
                                              viewModel.playPlaylist(
                                                isSameSource,
                                                source,
                                              ),
                                          displayPauseButton:
                                              isSameSource && isPlaying,
                                          downloadCallback: () {
                                            if (!viewModel.downloaded) {
                                              viewModel.downloadPlaylist();
                                              return;
                                            }
                                            viewModel
                                                .removeDownloadedPlaylist();
                                          },
                                          downloaded: viewModel.downloaded,
                                          contextMenuKey:
                                              playlistContextMenuKey,
                                          menuController:
                                              playlistContextMenuController,
                                        )
                                      : MobilePlaylistHeader(
                                          name: playlist.name,
                                          type: t.general.playlist,
                                          imageUrl: playlist
                                              .getCompressedCoverUrl(
                                                TrackCompressedCoverQuality
                                                    .high,
                                              ),
                                          year: "",
                                          tracks: playlist.tracks,
                                          artists: const [],
                                          playCallback: () =>
                                              viewModel.playPlaylist(
                                                isSameSource,
                                                source,
                                              ),
                                          displayPauseButton:
                                              isSameSource && isPlaying,
                                          downloadCallback: () {
                                            if (!viewModel.downloaded) {
                                              viewModel.downloadPlaylist();
                                              return;
                                            }
                                            viewModel
                                                .removeDownloadedPlaylist();
                                          },
                                          downloaded: viewModel.downloaded,
                                          contextMenuKey:
                                              playlistContextMenuKey,
                                          menuController:
                                              playlistContextMenuController,
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
                        sliver: Consumer<PlaylistViewModel>(
                          builder: (context, viewModel, _) {
                            if (viewModel.playlist == null) {
                              return SliverToBoxAdapter();
                            }

                            return StickyDesktopTrackHeader(
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
                            );
                          },
                        ),
                      ),
                      SliverContainer(
                        maxWidth: maxWidth,
                        padding: EdgeInsets.only(left: padding, right: padding),
                        sliver: Consumer<PlaylistViewModel>(
                          builder: (context, viewModel, _) {
                            final playlist = viewModel.playlist;

                            if (playlist == null) {
                              return SliverToBoxAdapter();
                            }

                            return TrackList(
                              tracks: playlist.tracks,
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
                              singleCustomActionsBuilder:
                                  (
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
                                        child: Text(
                                          t.actions.removeFromPlaylist,
                                        ),
                                        onPressed: () async {
                                          menuController.close();
                                          await viewModel
                                              .removeTracksFromPlaylist(
                                                context,
                                                {index},
                                              );
                                          unselect();
                                        },
                                      ),
                                    ];
                                  },
                              multiCustomActionsBuilder:
                                  (
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
                                        child: Text(
                                          t.actions.removeFromPlaylist,
                                        ),
                                        onPressed: () async {
                                          menuController.close();
                                          await viewModel
                                              .removeTracksFromPlaylist(
                                                context,
                                                selectedIndexes,
                                              );
                                          unselect();
                                        },
                                      ),
                                    ];
                                  },
                              source:
                                  "${t.general.playlist} \"${playlist.name}\"",
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
          Selector<PlaylistViewModel, bool>(
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
