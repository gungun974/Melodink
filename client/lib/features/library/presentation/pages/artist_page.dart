import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/artist_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/album_collections_grid.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_artist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_artist_header.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';

class ArtistPage extends ConsumerWidget {
  final String artistId;

  const ArtistPage({
    super.key,
    required this.artistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArtist = ref.watch(artistByIdProvider(artistId));

    final artist = asyncArtist.valueOrNull;

    if (artist == null) {
      return AppNavigationHeader(
        title: AppScreenTypeLayoutBuilders(
          mobile: (_) => const Text("Artist"),
        ),
        child: Container(),
      );
    }

    final appearAlbums = artist.appearAlbums
        .where((album) => !artist.albums.contains(album))
        .toList();

    return AppNavigationHeader(
      title: AppScreenTypeLayoutBuilders(
        mobile: (_) => const Text("Artist"),
      ),
      child: AppScreenTypeLayoutBuilder(builder: (context, size) {
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
              sliver: size == AppScreenTypeLayout.desktop
                  ? DesktopArtistHeader(
                      name: artist.name,
                      imageUrl: artist.getCompressedCoverUrl(
                        TrackCompressedCoverQuality.high,
                      ),
                    )
                  : MobileArtistHeader(
                      name: artist.name,
                      imageUrl: artist.getCompressedCoverUrl(
                        TrackCompressedCoverQuality.high,
                      ),
                    ),
            ),
            if (artist.albums.isNotEmpty)
              SliverContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 8.0,
                ),
                sliver: const SliverToBoxAdapter(
                  child: Text(
                    "Albums",
                    style: TextStyle(
                      fontSize: 40,
                      letterSpacing: 40 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            if (artist.albums.isNotEmpty)
              SliverContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 8.0,
                ),
                sliver: AlbumCollectionsGrid(
                  albums: artist.albums,
                ),
              ),
            if (appearAlbums.isNotEmpty)
              SliverContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 8.0,
                ),
                sliver: const SliverToBoxAdapter(
                  child: Text(
                    "Appeared in",
                    style: TextStyle(
                      fontSize: 40,
                      letterSpacing: 40 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            if (appearAlbums.isNotEmpty)
              SliverContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 8.0,
                ),
                sliver: AlbumCollectionsGrid(
                  albums: appearAlbums,
                ),
              ),
            if (artist.hasRoleAlbums.isNotEmpty)
              SliverContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 8.0,
                ),
                sliver: const SliverToBoxAdapter(
                  child: Text(
                    "Has role in",
                    style: TextStyle(
                      fontSize: 40,
                      letterSpacing: 40 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            if (artist.hasRoleAlbums.isNotEmpty)
              SliverContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 8.0,
                ),
                sliver: AlbumCollectionsGrid(
                  albums: artist.hasRoleAlbums,
                ),
              ),
          ],
        );
      }),
    );
  }
}
