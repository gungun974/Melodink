import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/presentation/widgets/playlist_context_menu.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:provider/provider.dart';

class PlaylistCollectionsGrid extends StatelessWidget {
  final List<Playlist> playlists;

  const PlaylistCollectionsGrid({super.key, required this.playlists});

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
          delegate: SliverChildBuilderDelegate((context, index) {
            final playlist = playlists[index];

            return HookBuilder(
              builder: (context) {
                final playlistContextMenuKey = useMemoized(() => GlobalKey());

                final playlistContextMenuController = useMemoized(
                  () => MenuController(),
                );

                return PlaylistContextMenu(
                  key: playlistContextMenuKey,
                  menuController: playlistContextMenuController,
                  playlist: playlist,
                  child: InkWell(
                    onTap: () {
                      context.read<AppRouter>().push(
                        "/playlist/${playlist.id}",
                      );
                    },
                    onSecondaryTapDown: (TapDownDetails details) {
                      playlistContextMenuController.open(
                        position: details.localPosition + const Offset(5, 5),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: AuthCachedNetworkImage(
                            fit: BoxFit.contain,
                            imageUrl: playlist.getCompressedCoverUrl(
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
                  ),
                );
              },
            );
          }, childCount: playlists.length),
        );
      },
    );
  }
}
