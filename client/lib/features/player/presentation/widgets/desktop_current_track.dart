import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/is_touch_device.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_error_overlay.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/hooks/use_get_download_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/album_link_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/single_track_context_menu.dart';

class DesktopCurrentTrack extends HookConsumerWidget {
  const DesktopCurrentTrack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final trackContextMenuController = useMemoized(() => MenuController());

    return StreamBuilder(
      stream: audioController.currentTrack.stream,
      builder: (context, snapshot) {
        final currentTrack = snapshot.data;
        if (currentTrack == null) {
          return Container();
        }

        audioController.previousTracks.valueOrNull?.take(5).forEach((track) {
          ImageCacheManager.preCache(
            track.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
            context,
          );
        });

        audioController.nextTracks.valueOrNull?.take(5).forEach((track) {
          ImageCacheManager.preCache(
            track.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
            context,
          );
        });

        return HookConsumer(
          builder: (context, ref, child) {
            final downloadedTrack = useGetDownloadTrack(currentTrack.id, ref);

            return SingleTrackContextMenu(
              track: currentTrack,
              menuController: trackContextMenuController,
              child: Container(
                color: const Color.fromRGBO(0, 0, 0, 0.08),
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onSecondaryTapDown: isTouchDevice(context)
                      ? null
                      : (TapDownDetails details) {
                          trackContextMenuController.open(
                            position:
                                details.localPosition + const Offset(5, 5),
                          );
                        },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: () {
                          GoRouter.of(context).push("/player");
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: PlayerErrorOverlay(
                            child: AuthCachedNetworkImage(
                              fit: BoxFit.contain,
                              imageUrl:
                                  downloadedTrack?.getCoverUrl() ??
                                  currentTrack.getCompressedCoverUrl(
                                    TrackCompressedCoverQuality.medium,
                                  ),
                              placeholder: (context, url) => Image.asset(
                                "assets/melodink_track_cover_not_found.png",
                              ),
                              errorWidget: (context, url, error) {
                                return Image.asset(
                                  "assets/melodink_track_cover_not_found.png",
                                );
                              },
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AlbumLinkText(
                        text: currentTrack.title,
                        albumId: currentTrack.albums.firstOrNull?.id,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 14 * 0.03,
                        ),
                        openWithScrollOnSpecificTrackId: currentTrack.id,
                      ),
                      const SizedBox(height: 4),
                      ArtistsLinksText(
                        artists: currentTrack.artists,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 12 * 0.03,
                          color: Colors.grey[350],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AlbumLinkText(
                        text: currentTrack.albums
                            .map((album) => album.name)
                            .join(", "),
                        albumId: currentTrack.albums.firstOrNull?.id,
                        style: TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[350],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
