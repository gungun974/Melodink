import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';

class AlbumCollectionsGrid extends StatelessWidget {
  final List<Album> albums;

  const AlbumCollectionsGrid({
    super.key,
    required this.albums,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;

        const maxCrossAxisExtent = 200.0;
        const crossAxisSpacing = 16.0;
        const childAspectRatio = 200 / 300;

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
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final album = albums[index];

              return InkWell(
                onTap: () {
                  GoRouter.of(context).go("/album/${album.id}");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthCachedNetworkImage(
                      imageUrl: album.getCoverUrl(),
                      placeholder: (context, url) => Image.asset(
                        "assets/melodink_track_cover_not_found.png",
                      ),
                      errorWidget: (context, url, error) {
                        return Image.asset(
                          "assets/melodink_track_cover_not_found.png",
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Tooltip(
                      message: album.name,
                      waitDuration: const Duration(milliseconds: 800),
                      child: Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.albumArtist,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: albums.length,
          ),
        );
      },
    );
  }
}
