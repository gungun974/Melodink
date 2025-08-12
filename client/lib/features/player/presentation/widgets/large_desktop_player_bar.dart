import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/routes/provider.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/like_track_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/open_queue_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/volume_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_error_overlay.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/album_link_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';

class LargeDesktopPlayerBar extends ConsumerWidget {
  const LargeDesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUrl = ref.watch(appRouterCurrentUrl);
    final scoringSystem = ref.watch(currentScoringSystemProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: currentUrl != "/player" ? 80 : 0,
      curve: Curves.easeInOutQuad,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: Container(
          height: 80,
          color: Colors.black,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: DesktopCurrentTrack2(),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 3),
                    PlayerControls(),
                    LargePlayerSeeker(),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.only(left: 12, right: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (scoringSystem != AppSettingScoringSystem.none)
                        CurrentTrackScoreControl(),
                      if (scoringSystem != AppSettingScoringSystem.none)
                        SizedBox(width: 12),
                      VolumeControl(),
                      SizedBox(width: 4),
                      OpenQueueControl(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DesktopCurrentTrack2 extends ConsumerWidget {
  const DesktopCurrentTrack2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return StreamBuilder(
      stream: audioController.currentTrack.stream,
      builder: (context, snapshot) {
        final currentTrack = snapshot.data;
        if (currentTrack == null) {
          return Container();
        }

        audioController.previousTracks.valueOrNull?.take(5).forEach(
          (track) {
            ImageCacheManager.preCache(
              track.getCompressedCoverUri(
                TrackCompressedCoverQuality.small,
              ),
              context,
            );
          },
        );

        audioController.nextTracks.valueOrNull?.take(5).forEach(
          (track) {
            ImageCacheManager.preCache(
              track.getCompressedCoverUri(
                TrackCompressedCoverQuality.small,
              ),
              context,
            );
          },
        );

        return Consumer(
          builder: (context, ref, child) {
            final downloadedTrack = ref
                .watch(
                  isTrackDownloadedProvider(currentTrack.id),
                )
                .valueOrNull;

            return Container(
              color: const Color.fromRGBO(0, 0, 0, 0.08),
              padding: const EdgeInsets.all(12),
              child: Row(
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
                          imageUrl: downloadedTrack?.getCoverUrl() ??
                              currentTrack.getCompressedCoverUrl(
                                TrackCompressedCoverQuality.small,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AlbumLinkText(
                          text: currentTrack.title,
                          albumId: currentTrack.albums.firstOrNull?.id,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 14 * 0.03,
                          ),
                          openWithScrollOnSpecificTrackId: currentTrack.id,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        ArtistsLinksText(
                          artists: currentTrack.artists,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 12 * 0.03,
                            color: Colors.grey[350],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
