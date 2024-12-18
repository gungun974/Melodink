import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/data/datasource/album_local_data_source.dart';
import 'package:melodink_client/features/library/data/datasource/album_remote_data_source.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';

class AlbumNotFoundException implements Exception {}

class AlbumRepository {
  final AlbumRemoteDataSource albumRemoteDataSource;
  final AlbumLocalDataSource albumLocalDataSource;

  final PlayedTrackRepository playedTrackRepository;

  final NetworkInfo networkInfo;

  AlbumRepository({
    required this.albumRemoteDataSource,
    required this.albumLocalDataSource,
    required this.playedTrackRepository,
    required this.networkInfo,
  });

  Future<List<Album>> getAllAlbums() async {
    final localAlbums = await albumLocalDataSource.getAllAlbums();

    if (networkInfo.isServerRecheable()) {
      try {
        final remoteAlbums = await albumRemoteDataSource.getAllAlbums();

        for (var i = 0; i < remoteAlbums.length; i++) {
          if (localAlbums.any((album) => album.id == remoteAlbums[i].id)) {
            remoteAlbums[i] = remoteAlbums[i].copyWith(isDownloaded: true);
          }
        }

        return remoteAlbums;
      } catch (_) {
        return localAlbums;
      }
    }

    return await albumLocalDataSource.getAllAlbums();
  }

  Future<Album> getAlbumById(String id) async {
    Album? album = await albumLocalDataSource.getAlbumById(id);

    album ??= await albumRemoteDataSource.getAlbumById(id);

    await playedTrackRepository.loadTrackHistoryIntoMinimalTracks(album.tracks);

    return album;
  }

  Future<Album> updateAndStoreAlbum(String id) async {
    final album = await albumRemoteDataSource.getAlbumById(id);
    await albumLocalDataSource.storeAlbum(album);

    await playedTrackRepository.loadTrackHistoryIntoMinimalTracks(album.tracks);

    return album;
  }

  Future<void> deleteStoredAlbum(String id) async {
    await albumLocalDataSource.deleteStoredAlbum(id);
  }

  Future<bool> isAlbumDownloaded(String id) async {
    final album = await albumLocalDataSource.getAlbumById(id);

    return album != null;
  }

  Future<Album> changeAlbumCover(String id, File file) async {
    return await albumRemoteDataSource.changeAlbumCover(id, file);
  }

  Future<Album> removeAlbumCover(String id) async {
    return await albumRemoteDataSource.removeAlbumCover(id);
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
    playedTrackRepository: ref.watch(
      playedTrackRepositoryProvider,
    ),
    networkInfo: ref.watch(
      networkInfoProvider,
    ),
  ),
);
