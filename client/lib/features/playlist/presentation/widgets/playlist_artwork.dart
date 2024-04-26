import 'package:flutter/material.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';

class PlaylistArtwork extends StatelessWidget {
  final Playlist playlist;

  final double? width;

  final double? height;

  final BoxFit? fit;

  const PlaylistArtwork({
    super.key,
    required this.playlist,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;

    switch (playlist.type) {
      case PlaylistType.album:
        image = NetworkImage(
          "$appUrl/api/playlist/album/${playlist.id}/image",
        );
        break;
      case PlaylistType.artist:
        break;
      case PlaylistType.custom:
        break;
      case PlaylistType.allTracks:
        image = const NetworkImage(
          "https://misc.scdn.co/liked-songs/liked-songs-300.png",
        );
        break;
    }

    final notFoundImage = Image.asset(
      "assets/melodink_track_cover_not_found.png",
      width: width,
      height: height,
      fit: fit,
    );

    return AspectRatio(
      aspectRatio: 1,
      child: image != null
          ? FadeInImage(
              placeholder: const AssetImage(
                "assets/melodink_track_cover_not_found.png",
              ),
              fadeInDuration: const Duration(milliseconds: 150),
              fadeInCurve: Curves.easeOutQuint,
              image: image,
              imageErrorBuilder: (context, error, stackTrace) {
                return notFoundImage;
              },
              width: width,
              height: height,
              fit: fit,
            )
          : notFoundImage,
    );
  }
}
