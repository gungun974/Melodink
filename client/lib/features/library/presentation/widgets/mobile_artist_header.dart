import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';

class MobileArtistHeader extends StatelessWidget {
  final String name;
  final String imageUrl;

  const MobileArtistHeader({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 48.0,
              vertical: 6.0,
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: AuthCachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => Image.asset(
                  "assets/melodink_track_cover_not_found.png",
                ),
                errorWidget: (context, url, error) {
                  return Image.asset(
                    "assets/melodink_track_cover_not_found.png",
                  );
                },
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 48,
              letterSpacing: 48 * 0.03,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
