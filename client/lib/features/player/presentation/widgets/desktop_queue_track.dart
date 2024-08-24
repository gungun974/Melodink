import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class DesktopQueueTrack extends StatelessWidget {
  final MinimalTrack track;

  final int trackNumber;

  final void Function(MinimalTrack track) playCallback;

  const DesktopQueueTrack({
    super.key,
    required this.track,
    required this.trackNumber,
    required this.playCallback,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        playCallback(track);
      },
      child: SizedBox(
        height: 50,
        child: Container(
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  "$trackNumber",
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 14 * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            fontSize: 14,
                            letterSpacing: 14 * 0.03,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.albumArtist,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 14 * 0.03,
                            color: Colors.grey[350],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  track.album,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 14 * 0.03,
                    color: Colors.grey[350],
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  durationToTime(track.duration),
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 14 * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                padding: const EdgeInsets.only(right: 4),
                constraints: const BoxConstraints(),
                icon: const AdwaitaIcon(AdwaitaIcons.menu),
                iconSize: 20.0,
                onPressed: () async {},
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
