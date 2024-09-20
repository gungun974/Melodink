import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/mobile_track.dart';

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
      return Container();
    }

    return AppScreenTypeLayoutBuilder(
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
                      artist: "",
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
                      artist: "",
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
                  height: size == AppScreenTypeLayout.desktop ? null : 8,
                  child: size == AppScreenTypeLayout.desktop
                      ? const DesktopTrackHeader()
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
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    late final Widget child;

                    if (size == AppScreenTypeLayout.mobile) {
                      child = MobileTrack(
                        track: tracks[index],
                        playCallback: (track) async {
                          await audioController.loadTracks(
                            tracks,
                            startAt: index,
                          );
                        },
                      );
                    } else {
                      child = DesktopTrack(
                        track: tracks[index],
                        trackNumber: index + 1,
                        playCallback: (track) async {
                          await audioController.loadTracks(
                            tracks,
                            startAt: index,
                          );
                        },
                      );
                    }

                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            size == AppScreenTypeLayout.desktop ? 0 : 12,
                      ),
                      color: const Color.fromRGBO(0, 0, 0, 0.03),
                      child: child,
                    );
                  },
                  childCount: tracks.length,
                ),
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
                      bottom: Radius.circular(
                        8,
                      ),
                    ),
                  ),
                  height: 8,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
