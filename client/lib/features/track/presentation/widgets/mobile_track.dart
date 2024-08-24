import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class MobileTrack extends StatelessWidget {
  final MinimalTrack track;

  final void Function(MinimalTrack track) playCallback;

  const MobileTrack({
    super.key,
    required this.track,
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
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: track.getCoverUrl(),
                        placeholder: (context, url) => Image.asset(
                          "assets/melodink_track_cover_not_found.png",
                        ),
                        errorWidget: (context, url, error) {
                          return Image.asset(
                            "assets/melodink_track_cover_not_found.png",
                          );
                        },
                      ),
                      const SizedBox(width: 10),
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
              ),
              IconButton(
                padding: const EdgeInsets.only(right: 4),
                constraints: const BoxConstraints(),
                icon: const AdwaitaIcon(AdwaitaIcons.view_more_horizontal),
                iconSize: 20.0,
                onPressed: () async {},
              )
            ],
          ),
        ),
      ),
    );
  }
}
