import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';

class ArtistCollectionsGrid extends StatelessWidget {
  final List<Artist> artists;

  const ArtistCollectionsGrid({
    super.key,
    required this.artists,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;

        final screenType = getAppScreenType(MediaQuery.of(context).size);

        const maxCrossAxisExtent = 200.0;
        const crossAxisSpacing = 16.0;
        final childAspectRatio =
            200 / (screenType == AppScreenTypeLayout.desktop ? 242 : 252);

        final rawCrossAxisCount = width / maxCrossAxisExtent;

        int crossAxisCount = rawCrossAxisCount.floor() + 1;

        if (rawCrossAxisCount <= 1.5) {
          crossAxisCount = 1;
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
            mainAxisSpacing: crossAxisSpacing,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final artist = artists[index];

              return InkWell(
                onTap: () {
                  GoRouter.of(context).push("/artist/${artist.id}");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      child: AuthCachedNetworkImage(
                        imageUrl: artist.getCoverUrl(),
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
                    const SizedBox(height: 8),
                    Tooltip(
                      message: artist.name,
                      waitDuration: const Duration(milliseconds: 800),
                      child: Text(
                        artist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: artists.length,
          ),
        );
      },
    );
  }
}
