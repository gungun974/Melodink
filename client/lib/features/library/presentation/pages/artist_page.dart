import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/artist_viewmodel.dart';
import 'package:melodink_client/features/library/presentation/widgets/album_collections_grid.dart';
import 'package:melodink_client/features/library/presentation/widgets/desktop_artist_header.dart';
import 'package:melodink_client/features/library/presentation/widgets/mobile_artist_header.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class ArtistPage extends StatelessWidget {
  final int artistId;

  const ArtistPage({super.key, required this.artistId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ArtistViewModel(
        eventBus: context.read(),
        artistRepository: context.read(),
      )..loadArtist(artistId),
      child: AppNavigationHeader(
        title: AppScreenTypeLayoutBuilders(
          mobile: (_) => Text(t.general.artist),
        ),
        child: AppScreenTypeLayoutBuilder(
          builder: (context, size) {
            final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
            final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

            return Consumer<ArtistViewModel>(
              builder: (context, viewModel, _) {
                final artist = viewModel.artist;

                if (artist == null) {
                  return SizedBox.shrink();
                }

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
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            t.general.albums,
                            style: const TextStyle(
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
                        sliver: AlbumCollectionsGrid(albums: artist.albums),
                      ),
                    if (artist.appearAlbums.isNotEmpty)
                      SliverContainer(
                        maxWidth: maxWidth,
                        padding: EdgeInsets.only(
                          left: padding,
                          right: padding,
                          top: 8.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            t.general.artistAppearedIn,
                            style: const TextStyle(
                              fontSize: 40,
                              letterSpacing: 40 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    if (artist.appearAlbums.isNotEmpty)
                      SliverContainer(
                        maxWidth: maxWidth,
                        padding: EdgeInsets.only(
                          left: padding,
                          right: padding,
                          top: 8.0,
                        ),
                        sliver: AlbumCollectionsGrid(
                          albums: artist.appearAlbums,
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
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            t.general.artistHasRole,
                            style: const TextStyle(
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
              },
            );
          },
        ),
      ),
    );
  }
}
