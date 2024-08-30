import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/duration_to_human.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class DesktopPlaylistHeader extends ConsumerWidget {
  final String name;
  final String type;
  final String imageUrl;

  final String description;

  final List<MinimalTrack> tracks;

  final String artist;

  final VoidCallback playCallback;

  const DesktopPlaylistHeader({
    super.key,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.description,
    required this.tracks,
    required this.artist,
    required this.playCallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return SliverToBoxAdapter(
      child: IntrinsicHeight(
        child: Row(
          children: [
            AuthCachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Image.asset(
                "assets/melodink_track_cover_not_found.png",
              ),
              errorWidget: (context, url, error) {
                return Image.asset(
                  "assets/melodink_track_cover_not_found.png",
                );
              },
              height: 256,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 16,
                      letterSpacing: 16 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 48,
                      letterSpacing: 48 * 0.03,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    [
                      "${tracks.length} Track${tracks.length > 1 ? 's' : ''}",
                      durationToHuman(
                        tracks.fold(
                          Duration.zero,
                          (sum, activity) => sum + activity.duration,
                        ),
                      )
                    ].join(" • "),
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 14 * 0.03,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 14 * 0.03,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onPressed: playCallback,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 48,
                        icon: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFC47ED0),
                            borderRadius: BorderRadius.circular(100.0),
                          ),
                          child: const Center(
                            child: AdwaitaIcon(
                              size: 32,
                              AdwaitaIcons.media_playback_start,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      StreamBuilder(
                        stream: audioController.playbackState,
                        builder: (context, snapshot) {
                          return IconButton(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const AdwaitaIcon(
                              AdwaitaIcons.media_playlist_shuffle,
                            ),
                            color: snapshot.data?.shuffleMode ==
                                    AudioServiceShuffleMode.all
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                            iconSize: 24.0,
                            onPressed: () async {
                              await audioController.toogleShufle();
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              artist,
                              style: const TextStyle(
                                fontSize: 14,
                                letterSpacing: 14 * 0.03,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: SvgPicture.asset(
                          "assets/icons/download.svg",
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        color: Colors.white,
                        iconSize: 24.0,
                        onPressed: () async {},
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
