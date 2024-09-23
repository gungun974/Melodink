import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/tiny_player_seeker.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';

class MobileCurrentTrackInfo extends ConsumerWidget {
  const MobileCurrentTrackInfo({super.key});

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
        return Consumer(builder: (context, ref, child) {
          final downloadedTrack = ref
              .watch(
                isTrackDownloadedProvider(currentTrack.id),
              )
              .valueOrNull;

          return GestureDetector(
            onTap: () {
              GoRouter.of(context).push("/player");
            },
            child: Container(
              color: Colors.black,
              height: 56,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              AuthCachedNetworkImage(
                                height: 40,
                                imageUrl: downloadedTrack?.getCoverUrl() ??
                                    currentTrack.getCoverUrl(),
                                placeholder: (context, url) => Image.asset(
                                  "assets/melodink_track_cover_not_found.png",
                                  height: 40,
                                ),
                                errorWidget: (context, url, error) {
                                  return Image.asset(
                                    "assets/melodink_track_cover_not_found.png",
                                    height: 40,
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentTrack.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      letterSpacing: 14 * 0.03,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentTrack.getVirtualAlbumArtist(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 14 * 0.03,
                                        color: Colors.grey[350]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        StreamBuilder<PlaybackState>(
                          stream: audioController.playbackState,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data?.playing ?? false;
                            return AppIconButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              icon: isPlaying
                                  ? const AdwaitaIcon(
                                      AdwaitaIcons.media_playback_pause)
                                  : const AdwaitaIcon(
                                      AdwaitaIcons.media_playback_start),
                              iconSize: 32.0,
                              onPressed: () async {
                                if (isPlaying) {
                                  await audioController.pause();
                                  return;
                                }
                                await audioController.play();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TinyPlayerSeeker(),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
