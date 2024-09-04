import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/library/data/datasource/album_local_data_source.dart';
import 'package:melodink_client/features/library/data/datasource/album_remote_data_source.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class AlbumNotFoundException implements Exception {}

class AlbumRepository {
  final AlbumRemoteDataSource albumRemoteDataSource;
  final AlbumLocalDataSource albumLocalDataSource;

  final DownloadTrackRepository downloadTrackRepository;

  AlbumRepository({
    required this.albumRemoteDataSource,
    required this.albumLocalDataSource,
    required this.downloadTrackRepository,
  });

  Future<List<Album>> getAllAlbums() async {
    try {
      final remoteAlbums = await albumRemoteDataSource.getAllAlbums();

      return remoteAlbums;
    } catch (_) {
      final localAlbums = await albumLocalDataSource.getAllAlbums();

      return localAlbums;
    }
  }

  Future<Album> getAlbumById(String id) async {
    Album? album = await albumLocalDataSource.getAlbumById(id);

    album ??= await albumRemoteDataSource.getAlbumById(id);

    final List<MinimalTrack> tracks = [];

    for (var i = 0; i < album.tracks.length; i++) {
      final track = album.tracks[i];
      tracks.add(
        track.copyWith(
          downloadedTrack: await downloadTrackRepository
              .getDownloadedTrackByTrackId(track.id),
        ),
      );
    }

    return album.copyWith(tracks: tracks);
  }

  Future<Album> updateAndStoreAlbum(String id) async {
    final album = await albumRemoteDataSource.getAlbumById(id);
    await albumLocalDataSource.storeAlbum(album);
    return album;
  }

  Future<void> deleteStoredAlbum(String id) async {
    await albumLocalDataSource.deleteStoredAlbum(id);
  }

  Future<bool> isAlbumDownloaded(String id) async {
    final album = await albumLocalDataSource.getAlbumById(id);

    return album != null;
  }
}

final albumRepositoryProvider = Provider(
  (ref) => AlbumRepository(
    albumRemoteDataSource: ref.watch(
      albumRemoteDataSourceProvider,
    ),
    albumLocalDataSource: ref.watch(
      albumLocalDataSourceProvider,
    ),
    downloadTrackRepository: ref.watch(
      downloadTrackRepositoryProvider,
    ),
  ),
);
