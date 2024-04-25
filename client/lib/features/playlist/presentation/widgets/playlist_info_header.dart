import 'package:flutter/material.dart';
import 'package:melodink_client/core/helpers/duration_to_human.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';

class TracksInfoHeader extends StatelessWidget {
  final Playlist playlist;

  const TracksInfoHeader({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = playlist.tracks.fold(
      const Duration(),
      (acc, track) => acc + track.duration,
    );

    final totalDurationHuman = durationToHuman(totalDuration);

    String playlistType = "Unknown";

    switch (playlist.type) {
      case PlaylistType.allTracks:
        playlistType = "All tracks";
        break;
      case PlaylistType.album:
        playlistType = "Album";
      case PlaylistType.artist:
        playlistType = "Artist";
      case PlaylistType.custom:
        playlistType = "Playlist";
    }

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
              Text(
                playlistType,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                playlist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 96,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (playlist.type == PlaylistType.album) ...[
                    Text(
                      playlist.albumArtist,
                      style: const TextStyle(
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
                    //   const SizedBox(width: 4),
                    //   const Text(
                    //     'YEAR???',
                    //     style: TextStyle(
                    //       color: Colors.white,
                    //       fontSize: 14,
                    //     ),
                    //   ),
                    //   const SizedBox(width: 4),
                    //   const Text(
                    //     '•',
                    //     style: TextStyle(
                    //       color: Colors.white,
                    //       fontSize: 14,
                    //     ),
                    //   ),
                  ],
                  const SizedBox(width: 4),
                  Text(
                    '${playlist.tracks.length} tracks, $totalDurationHuman',
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
