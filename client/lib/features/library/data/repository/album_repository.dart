import 'dart:async';
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
          final localAlbum = localAlbums
              .where(
                (album) => album.id == remoteAlbums[i].id,
              )
              .firstOrNull;

          if (localAlbum != null) {
            remoteAlbums[i] = remoteAlbums[i].copyWith(
              isDownloaded: true,
              downloadTracks: localAlbum.downloadTracks,
            );
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

  Future<Album> updateAndStoreAlbum(
      String id, bool shouldDownloadTracks) async {
    final album = await albumRemoteDataSource.getAlbumById(id);
    await albumLocalDataSource.storeAlbum(album, shouldDownloadTracks);

    await playedTrackRepository.loadTrackHistoryIntoMinimalTracks(album.tracks);

    return album;
  }

  Future<List<Album>> updateAndStoreAllAlbums(
    bool shouldDownloadTracks, [
    StreamController<double>? streamController,
  ]) async {
    final albums = await albumRemoteDataSource.getAllAlbumsWithTracks();

    final signatures =
        await albumRemoteDataSource.getAllAlbumsCoverSignatures();

    await albumLocalDataSource.storeAlbums(
      albums,
      shouldDownloadTracks,
      signatures,
      streamController,
    );

    return albums;
  }

  Future<void> deleteStoredAlbum(String id) async {
    await albumLocalDataSource.deleteStoredAlbum(id);
  }

  Future<void> deleteOrphanAlbums() async {
    await albumLocalDataSource.deleteOrphanAlbums();
  }

  Future<bool> isAlbumDownloaded(String id) async {
    final album = await albumLocalDataSource.getAlbumById(id);

    if (album == null) {
      return false;
    }

    return album.downloadTracks;
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
