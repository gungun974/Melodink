import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
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

    return Stack(
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
                                AppImageCacheProvider(track.getCoverUri()),
                                context);
                          },
                        );

                        audioController.nextTracks.valueOrNull?.take(5).forEach(
                          (track) {
                            precacheImage(
                                AppImageCacheProvider(track.getCoverUri()),
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
                                    isTrackDownloadedProvider(currentTrack.id),
                                  )
                                  .valueOrNull;

                              image = AuthCachedNetworkImage(
                                imageUrl: downloadedTrack?.getCoverUrl() ??
                                    currentTrack.getCoverUrl(),
                                placeholder: (context, url) => Image.asset(
                                  "assets/melodink_track_cover_not_found.png",
                                ),
                                errorWidget: (context, url, error) {
                                  return Image.asset(
                                    "assets/melodink_track_cover_not_found.png",
                                  );
                                },
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
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: AppIconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const AdwaitaIcon(
                                              AdwaitaIcons.heart_outline_thick),
                                          iconSize: 24.0,
                                          color: Colors.white,
                                          onPressed: () {
                                            GoRouter.of(context).push("/queue");
                                          },
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const AdwaitaIcon(AdwaitaIcons.music_queue),
                        iconSize: 24.0,
                        color: Colors.white,
                        onPressed: () {
                          GoRouter.of(context).push("/queue");
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
