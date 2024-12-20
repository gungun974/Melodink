import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/library/data/datasource/album_local_data_source.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';

class ArtistLocalDataSource {
  final AlbumLocalDataSource albumLocalDataSource;

  final DownloadTrackRepository downloadTrackRepository;

  ArtistLocalDataSource({
    required this.albumLocalDataSource,
    required this.downloadTrackRepository,
  });

  Future<List<Artist>> getAllArtists() async {
    final allAlbums = await albumLocalDataSource.getAllAlbums();

    final artists = <String, Artist>{};

    for (final album in allAlbums) {
      for (final track in album.tracks.toList(growable: false)
        ..sort(
          (a, b) => b.dateAdded.compareTo(a.dateAdded),
        )) {
        final downloadedTrack =
            await downloadTrackRepository.getDownloadedTrackByTrackId(track.id);

        if (downloadedTrack == null) {
          continue;
        }

        for (final artist in track.artists) {
          if (!artists.containsKey(artist.id)) {
            artists[artist.id] = Artist(
              id: artist.id,
              name: artist.name,
              // ignore: prefer_const_literals_to_create_immutables
              albums: [],
              // ignore: prefer_const_literals_to_create_immutables
              appearAlbums: [],
              // ignore: prefer_const_literals_to_create_immutables
              hasRoleAlbums: [],
              localCover: downloadedTrack.getCoverUrl(),
              lastTrackDateAdded: track.dateAdded,
            );
          }

          if (artists[artist.id]!
                  .appearAlbums
                  .indexWhere((lalbum) => lalbum.id == album.id) <
              0) {
            artists[artist.id]!.appearAlbums.add(album);
          }
        }

        for (final artist in track.albumArtists) {
          if (!artists.containsKey(artist.id)) {
            artists[artist.id] = Artist(
              id: artist.id,
              name: artist.name,
              // ignore: prefer_const_literals_to_create_immutables
              albums: [],
              // ignore: prefer_const_literals_to_create_immutables
              appearAlbums: [],
              // ignore: prefer_const_literals_to_create_immutables
              hasRoleAlbums: [],
              localCover: downloadedTrack.getCoverUrl(),
              lastTrackDateAdded: track.dateAdded,
            );
          }

          if (artists[artist.id]!
                  .albums
                  .indexWhere((lalbum) => lalbum.id == album.id) <
              0) {
            artists[artist.id]!.albums.add(album);
          }
        }
      }
    }

    return artists.values.toList();
  }

  Future<Artist?> getArtistById(String id) async {
    final artists = await getAllArtists();

    return artists.firstWhere(
      (artist) => artist.id == id,
    );
  }
}

final artistLocalDataSourceProvider = Provider(
  (ref) => ArtistLocalDataSource(
    albumLocalDataSource: ref.watch(
      albumLocalDataSourceProvider,
    ),
    downloadTrackRepository: ref.watch(
      downloadTrackRepositoryProvider,
    ),
  ),
);
