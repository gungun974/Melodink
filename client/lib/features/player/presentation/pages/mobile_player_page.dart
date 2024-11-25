import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:melodink_client/core/helpers/is_touch_device.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/like_track_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/open_queue_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_error_overlay.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/album_link_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';

class MobilePlayerPage extends ConsumerWidget {
  const MobilePlayerPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return Dismissible(
      direction: isTouchDevice(context)
          ? DismissDirection.down
          : DismissDirection.none,
      key: const Key('DesktopPlayerPageDown'),
      onDismissed: (_) => Navigator.of(context).pop(),
      child: Stack(
        children: [
          const GradientBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              leading: IconButton(
                icon: SvgPicture.asset(
                  "assets/icons/arrow-down.svg",
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: StreamBuilder<String?>(
                  stream: audioController.playerTracksFrom.stream,
                  builder: (context, snapshot) {
                    final source = snapshot.data;
                    if (source == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      source,
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 20 * 0.03,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  }),
              centerTitle: true,
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0.08),
              shadowColor: Colors.transparent,
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: Column(
                    children: [
                      StreamBuilder(
                        stream: audioController.currentTrack.stream,
                        builder: (context, snapshot) {
                          audioController.previousTracks.valueOrNull
                              ?.take(5)
                              .forEach(
                            (track) {
                              precacheImage(
                                  AppImageCacheProvider(
                                      track.getCompressedCoverUri(
                                    TrackCompressedCoverQuality.high,
                                  )),
                                  context);
                            },
                          );

                          audioController.nextTracks.valueOrNull
                              ?.take(5)
                              .forEach(
                            (track) {
                              precacheImage(
                                  AppImageCacheProvider(
                                      track.getCompressedCoverUri(
                                    TrackCompressedCoverQuality.high,
                                  )),
                                  context);
                            },
                          );

                          return Consumer(
                            builder: (context, ref, child) {
                              String title = "";

                              int? trackId;

                              List<MinimalArtist> artists = [];

                              String album = "";
                              String albumId = "";

                              Widget image = Image.asset(
                                "assets/melodink_track_cover_not_found.png",
                              );

                              final currentTrack = snapshot.data;

                              if (currentTrack != null) {
                                title = currentTrack.title;

                                trackId = currentTrack.id;

                                artists.addAll(currentTrack.artists);

                                album = currentTrack.album;
                                albumId = currentTrack.albumId;

                                final downloadedTrack = ref
                                    .watch(
                                      isTrackDownloadedProvider(
                                          currentTrack.id),
                                    )
                                    .valueOrNull;

                                image = PlayerErrorOverlay(
                                  child: AuthCachedNetworkImage(
                                    imageUrl: downloadedTrack?.getCoverUrl() ??
                                        currentTrack.getCompressedCoverUrl(
                                          TrackCompressedCoverQuality.high,
                                        ),
                                    placeholder: (context, url) => Image.asset(
                                      "assets/melodink_track_cover_not_found.png",
                                    ),
                                    errorWidget: (context, url, error) {
                                      return Image.asset(
                                        "assets/melodink_track_cover_not_found.png",
                                      );
                                    },
                                  ),
                                );
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(0, 0, 0, 0.03),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AspectRatio(
                                            aspectRatio: 1.0,
                                            child: image,
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AlbumLinkText(
                                                text: title,
                                                albumId: albumId,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                  letterSpacing: 16 * 0.03,
                                                ),
                                                openWithScrollOnSpecificTrackId:
                                                    trackId,
                                              ),
                                              const SizedBox(height: 4),
                                              ArtistsLinksText(
                                                artists: artists,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  letterSpacing: 14 * 0.03,
                                                  color: Colors.grey[350],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              AlbumLinkText(
                                                text: album,
                                                albumId: albumId,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  letterSpacing: 12 * 0.03,
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.grey[350],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: LikeTrackControl(
                                            largeControlButton: true,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.only(
                          top: 16,
                          left: 8,
                          right: 8,
                          bottom: 8,
                        ),
                        child: const Column(
                          children: [
                            LargePlayerSeeker(displayDurationsInBottom: true),
                            SizedBox(height: 16),
                            PlayerControls(largeControlsButton: true),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Spacer(),
                      OpenQueueControl(
                        largeControlButton: true,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
