import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:melodink_client/core/helpers/is_touch_device.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/like_track_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/open_queue_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_play_pause_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_repeat_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_shuffle_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_skip_to_next_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_skip_to_previous_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/volume_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/album_link_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';

class DesktopPlayerPage extends ConsumerWidget {
  const DesktopPlayerPage({
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
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
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
            body: LayoutBuilder(builder: (context, constraints) {
              return MaxContainer(
                maxWidth: 1920,
                padding: EdgeInsets.only(
                  left: 64,
                  right: 64,
                  top:
                      constraints.maxHeight * constraints.maxHeight * 0.000118 +
                          constraints.maxHeight * 0.01 -
                          25,
                  bottom:
                      constraints.maxHeight * constraints.maxHeight * 0.000025 +
                          constraints.maxHeight * 0.08 -
                          25,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: min(constraints.maxWidth * 0.3, 600),
                            child: StreamBuilder(
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

                                      image = AuthCachedNetworkImage(
                                        imageUrl: downloadedTrack
                                                ?.getCoverUrl() ??
                                            currentTrack.getCompressedCoverUrl(
                                              TrackCompressedCoverQuality.high,
                                            ),
                                        placeholder: (context, url) =>
                                            Image.asset(
                                          "assets/melodink_track_cover_not_found.png",
                                        ),
                                        errorWidget: (context, url, error) {
                                          return Image.asset(
                                            "assets/melodink_track_cover_not_found.png",
                                          );
                                        },
                                      );
                                    }

                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 600,
                                            ),
                                            child: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: AspectRatio(
                                                aspectRatio: 1.0,
                                                child: image,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  AlbumLinkText(
                                                    text: title,
                                                    albumId: albumId,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 20,
                                                      letterSpacing: 20 * 0.03,
                                                    ),
                                                    openWithScrollOnSpecificTrackId:
                                                        trackId,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ArtistsLinksText(
                                                    artists: artists,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      letterSpacing: 18 * 0.03,
                                                      color: Colors.grey[350],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  AlbumLinkText(
                                                    text: album,
                                                    albumId: albumId,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      letterSpacing: 16 * 0.03,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                      color: Colors.grey[350],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 32),
                          const Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: SizedBox.shrink(),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Spacer(),
                                    SizedBox(
                                      width: 300,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          PlayerShuffleControl(
                                            largeControlButton: true,
                                          ),
                                          PlayerSkipToPreviousControl(
                                            largeControlButton: true,
                                          ),
                                          PlayerPlayPauseControl(
                                            largeControlButton: false,
                                          ),
                                          PlayerSkipToNextControl(
                                            largeControlButton: true,
                                          ),
                                          PlayerRepeatControl(
                                            largeControlButton: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Spacer(),
                                    VolumeControl(
                                      largeControlButton: true,
                                    ),
                                    SizedBox(width: 4),
                                    OpenQueueControl(
                                      largeControlButton: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LargePlayerSeeker(
                            displayDurationsInBottom: true,
                            large: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}