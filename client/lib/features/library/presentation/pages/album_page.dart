import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/album_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_playlist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_playlist_header.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/mobile_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';

class AlbumPage extends ConsumerWidget {
  final String albumId;

  const AlbumPage({
    super.key,
    required this.albumId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final asyncAlbum = ref.watch(albumByIdProvider(albumId));
    final albumDownload = ref.watch(albumDownloadNotifierProvider(albumId));

    final tracks = ref.watch(albumSortedTracksProvider(albumId));

    final album = asyncAlbum.valueOrNull;

    if (album == null) {
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
                      name: album.name,
                      type: "Album",
                      imageUrl: album.getCoverUrl(),
                      description: "",
                      tracks: tracks,
                      artists: album.albumArtists,
                      playCallback: () async {
                        await audioController.loadTracks(
                          tracks,
                        );
                      },
                      downloadCallback: () async {
                        final albumDownloadNotifier = ref.read(
                          albumDownloadNotifierProvider(album.id).notifier,
                        );

                        if (!albumDownload.downloaded) {
                          await albumDownloadNotifier.download();
                        } else {
                          await albumDownloadNotifier.deleteDownloaded();
                        }
                      },
                      downloaded: albumDownload.downloaded,
                    )
                  : MobilePlaylistHeader(
                      name: album.name,
                      type: "Album",
                      imageUrl: album.getCoverUrl(),
                      tracks: tracks,
                      artists: album.albumArtists,
                      playCallback: () async {
                        await audioController.loadTracks(
                          tracks,
                        );
                      },
                      downloadCallback: () async {
                        final albumDownloadNotifier = ref.read(
                          albumDownloadNotifierProvider(album.id).notifier,
                        );

                        if (!albumDownload.downloaded) {
                          await albumDownloadNotifier.download();
                        } else {
                          await albumDownloadNotifier.deleteDownloaded();
                        }
                      },
                      downloaded: albumDownload.downloaded,
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
                      ? const DesktopTrackHeader(
                          displayAlbum: false,
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
                displayImage: false,
                displayAlbum: false,
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
