import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';

class PlaylistCollectionsGrid extends StatelessWidget {
  final List<Playlist> playlists;

  const PlaylistCollectionsGrid({
    super.key,
    required this.playlists,
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
              final playlist = playlists[index];

              return InkWell(
                onTap: () {
                  GoRouter.of(context).go("/playlist/${playlist.id}");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthCachedNetworkImage(
                      imageUrl: playlist.getCoverUrl(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: playlist.name,
                            waitDuration: const Duration(milliseconds: 800),
                            child: Text(
                              playlist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        playlist.isDownloaded
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
            childCount: playlists.length,
          ),
        );
      },
    );
  }
}
