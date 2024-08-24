import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/injection_container.dart';

class DesktopCurrentTrack extends StatefulWidget {
  const DesktopCurrentTrack({super.key});

  @override
  State<DesktopCurrentTrack> createState() => _DesktopCurrentTrackState();
}

class _DesktopCurrentTrackState extends State<DesktopCurrentTrack> {
  final AudioController audioController = sl();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: audioController.currentTrack.stream,
      builder: (context, snapshot) {
        final currentTrack = snapshot.data;
        if (currentTrack == null) {
          return Container();
        }
        return Container(
          color: const Color.fromRGBO(0, 0, 0, 0.08),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: CachedNetworkImage(
                  imageUrl: currentTrack.getCoverUrl(),
                  placeholder: (context, url) => Image.asset(
                    "assets/melodink_track_cover_not_found.png",
                  ),
                  errorWidget: (context, url, error) {
                    return Image.asset(
                      "assets/melodink_track_cover_not_found.png",
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentTrack.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 14 * 0.03,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentTrack.albumArtist,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 12 * 0.03,
                  color: Colors.grey[350],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentTrack.album,
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[350],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
