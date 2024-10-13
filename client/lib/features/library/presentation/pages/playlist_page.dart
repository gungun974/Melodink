import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';

class PlaylistPage extends ConsumerWidget {
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

    if (playlist == null) {
      return AppNavigationHeader(
        title: AppScreenTypeLayoutBuilders(
          mobile: (_) => const Text("Playlist"),
        ),
        child: Container(),
      );
    }

    return AppNavigationHeader(
      title: AppScreenTypeLayoutBuilders(
        mobile: (_) => const Text("Playlist"),
      ),
      child: AppScreenTypeLayoutBuilder(
        builder: (context, size) {
          final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
          final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

          final separator = size == AppScreenTypeLayout.desktop ? 16.0 : 12.0;

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
                        imageUrl: playlist.getCoverUrl(),
                        description: playlist.description,
                        tracks: tracks,
                        artists: const [],
                        playCallback: () async {
                          await audioController.loadTracks(
                            tracks,
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
                            await playlistDownloadNotifier.deleteDownloaded();
                          }
                        },
                        downloaded: playlistDownload.downloaded,
                      )
                    : MobilePlaylistHeader(
                        name: playlist.name,
                        type: "Playlist",
                        imageUrl: playlist.getCoverUrl(),
                        tracks: tracks,
                        artists: const [],
                        playCallback: () async {
                          await audioController.loadTracks(
                            tracks,
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
                            await playlistDownloadNotifier.deleteDownloaded();
                          }
                        },
                        downloaded: playlistDownload.downloaded,
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
                            displayLastPlayed: true,
                            displayPlayedCount: true,
                            displayQuality: true,
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
                  displayTrackIndex: false,
                  displayLastPlayed: true,
                  displayPlayedCount: true,
                  displayQuality: true,
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
                        onPressed: () {
                          ref
                              .read(
                                  playlistContextMenuNotifierProvider.notifier)
                              .removeTracks(
                                playlist,
                                index,
                                index,
                              );
                          menuController.close();
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
                        onPressed: () {
                          ref
                              .read(
                                  playlistContextMenuNotifierProvider.notifier)
                              .removeTracks(
                                playlist,
                                startIndex,
                                endIndex,
                              );
                          menuController.close();
                          unselect();
                        },
                      ),
                    ];
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),
            ],
          );
        },
      ),
    );
  }
}
