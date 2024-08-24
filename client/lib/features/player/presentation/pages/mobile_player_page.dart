import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
import 'package:melodink_client/injection_container.dart';

class MobilePlayerPage extends StatefulWidget {
  const MobilePlayerPage({
    super.key,
  });

  @override
  State<MobilePlayerPage> createState() => _MobilePlayerPageState();
}

class _MobilePlayerPageState extends State<MobilePlayerPage> {
  final AudioController audioController = sl();

  @override
  Widget build(BuildContext context) {
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
                        String title = "";

                        String artist = "";

                        String album = "";

                        Widget image = Image.asset(
                          "assets/melodink_track_cover_not_found.png",
                        );

                        final currentTrack = snapshot.data;

                        if (currentTrack != null) {
                          title = currentTrack.title;

                          artist = currentTrack.albumArtist;

                          album = currentTrack.album;

                          image = CachedNetworkImage(
                            imageUrl: currentTrack.getCoverUrl(),
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
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          letterSpacing: 16 * 0.03,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        artist,
                                        style: TextStyle(
                                          fontSize: 14,
                                          letterSpacing: 14 * 0.03,
                                          color: Colors.grey[350],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        album,
                                        style: TextStyle(
                                          fontSize: 12,
                                          letterSpacing: 12 * 0.03,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.grey[350],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
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
