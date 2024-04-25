import 'package:flutter/material.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:sliver_tools/sliver_tools.dart';

class PlaylistCollectionsGrid extends StatefulWidget {
  final String title;

  final List<Playlist> playlists;

  const PlaylistCollectionsGrid({
    super.key,
    required this.title,
    required this.playlists,
  });

  @override
  State<PlaylistCollectionsGrid> createState() =>
      _PlaylistCollectionsGridState();
}

class _PlaylistCollectionsGridState extends State<PlaylistCollectionsGrid> {
  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAll = !showAll;
                    });
                  },
                  child: Text(
                    showAll ? "Show less" : "Show all",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverLayoutBuilder(builder: (context, constraints) {
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
                final playlist = widget.playlists[index];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Image.asset(
                        "assets/melodink_track_cover_not_found.png",
                      ),
                    ),
                    const SizedBox(height: 8),
                    Tooltip(
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
                    const SizedBox(height: 4),
                    if (playlist.type == PlaylistType.album)
                      Text(
                        playlist.albumArtist,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                );
              },
              childCount: showAll ? widget.playlists.length : crossAxisCount,
            ),
          );
        }),
      ],
    );
  }
}
