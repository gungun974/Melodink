import 'package:flutter/material.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/injection_container.dart';

class CurrentTrackInfo extends StatefulWidget {
  const CurrentTrackInfo({super.key});

  @override
  State<CurrentTrackInfo> createState() => _CurrentTrackInfoState();
}

class _CurrentTrackInfoState extends State<CurrentTrackInfo> {
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
        return Row(
          children: [
            FadeInImage(
              height: 40,
              placeholder: const AssetImage(
                "assets/melodink_track_cover_not_found.png",
              ),
              image: NetworkImage(currentTrack.getCoverUrl()),
              imageErrorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  "assets/melodink_track_cover_not_found.png",
                  width: 40,
                  height: 40,
                );
              },
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key: const Key("titleText"),
                  currentTrack.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  key: const Key("artistText"),
                  currentTrack.albumArtist,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
