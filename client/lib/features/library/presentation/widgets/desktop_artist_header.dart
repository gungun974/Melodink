import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';

class DesktopArtistHeader extends StatelessWidget {
  final String name;
  final String imageUrl;

  const DesktopArtistHeader({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: IntrinsicHeight(
        child: Row(
          children: [
            AuthCachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Image.asset(
                "assets/melodink_track_cover_not_found.png",
              ),
              errorWidget: (context, url, error) {
                return Image.asset(
                  "assets/melodink_track_cover_not_found.png",
                );
              },
              height: 256,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Artist",
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 16 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
