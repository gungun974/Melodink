import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_seeker.dart';
import 'package:melodink_client/injection_container.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final AudioController audioController = sl();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.black87,
          ),
          const GradientBackground(),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              Expanded(
                child: StreamBuilder(
                  stream: audioController.currentTrack.stream,
                  builder: (context, snapshot) {
                    String title = "";

                    String artist = "";

                    ImageProvider<Object> image = const AssetImage(
                      "assets/melodink_track_cover_not_found.png",
                    );

                    final currentTrack = snapshot.data;

                    if (currentTrack != null) {
                      title = currentTrack.title;

                      artist = currentTrack.albumArtist;

                      image = NetworkImage(currentTrack.getCoverUrl());
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 24.0,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FadeInImage(
                                placeholder: const AssetImage(
                                  "assets/melodink_track_cover_not_found.png",
                                ),
                                image: image,
                                imageErrorBuilder:
                                    (context, error, stackTrace) {
                                  return Image.asset(
                                    "assets/melodink_track_cover_not_found.png",
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    key: const Key("titleText"),
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    key: const Key("artistText"),
                                    artist,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const PlayerSeeker(
                            autoMaxWidth: false,
                            showBottomDurations: true,
                          ),
                          const SizedBox(height: 8),
                          const PlayerControls(
                            smallControlsButton: false,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Spacer(),
                              IconButton(
                                padding: const EdgeInsets.only(),
                                icon:
                                    const AdwaitaIcon(AdwaitaIcons.music_queue),
                                iconSize: 20.0,
                                color: Colors.white,
                                onPressed: () {
                                  GoRouter.of(context).push("/queue");
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
