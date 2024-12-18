import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';

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

        final screenType = getAppScreenType(MediaQuery.of(context).size);

        const maxCrossAxisExtent = 200.0;
        const crossAxisSpacing = 16.0;
        final childAspectRatio =
            200 / (screenType == AppScreenTypeLayout.desktop ? 262 : 272);

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
              final album = albums[index];

              return InkWell(
                onTap: () {
                  GoRouter.of(context).push("/album/${album.id}");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthCachedNetworkImage(
                      imageUrl: album.getCompressedCoverUrl(
                        TrackCompressedCoverQuality.medium,
                      ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: album.albumArtists
                                .map((artist) => artist.name)
                                .join(", "),
                            waitDuration: const Duration(milliseconds: 800),
                            child: Text(
                              album.albumArtists
                                  .map((artist) => artist.name)
                                  .join(", "),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        album.isDownloaded && album.downloadTracks
                            ? Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: SvgPicture.asset(
                                  "assets/icons/download2.svg",
                                  width: 15,
                                  height: 15,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
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
