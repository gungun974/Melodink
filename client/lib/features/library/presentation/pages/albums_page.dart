import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/album_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/album_collections_grid.dart';

class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlbums = ref.watch(allAlbumsProvider);

    final albums = asyncAlbums.valueOrNull;

    if (albums == null) {
      return Container();
    }

    return AppScreenTypeLayoutBuilder(builder: (context, size) {
      final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
      final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

      return CustomScrollView(
        slivers: [
          SliverContainer(
            maxWidth: maxWidth,
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: 16.0,
            ),
            sliver: const SliverToBoxAdapter(
              child: Text(
                "Albums",
                style: TextStyle(
                  fontSize: 48,
                  letterSpacing: 48 * 0.03,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverContainer(
            maxWidth: maxWidth,
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: 16.0,
            ),
            sliver: AlbumCollectionsGrid(
              albums: albums,
            ),
          ),
        ],
      );
    });
  }
}