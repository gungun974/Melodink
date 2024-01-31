import 'package:flutter/material.dart';
import 'package:melodink_client/core/helpers/duration_to_human.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';

class TracksInfoHeader extends StatelessWidget {
  final List<Track> tracks;

  const TracksInfoHeader({
    super.key,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = tracks.fold(
      const Duration(),
      (acc, track) => acc + track.duration,
    );

    final totalDurationHuman = durationToHuman(totalDuration);

    return IntrinsicHeight(
      child: Row(
        children: [
          Image.network(
            "https://misc.scdn.co/liked-songs/liked-songs-300.png",
            height: 150.0,
            width: 150.0,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All tracks',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              const Text(
                'All tracks',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 96,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  /* const Text(
                    'Artist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '2016',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4), */
                  Text(
                    '${tracks.length} tracks, $totalDurationHuman',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
