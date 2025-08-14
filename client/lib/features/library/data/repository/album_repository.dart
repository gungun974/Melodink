import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/sync/data/models/album_model.dart';
import 'package:melodink_client/features/sync/data/repository/sync_repository.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class AlbumNotFoundException implements Exception {}

class AlbumRepository {
  final PlayedTrackRepository playedTrackRepository;
  final SyncRepository syncRepository;

  final NetworkInfo networkInfo;

  AlbumRepository({
    required this.playedTrackRepository,
    required this.syncRepository,
    required this.networkInfo,
  });

  static Album decodeAlbum(
    String applicationSupportDirectory,
    Map<String, Object?> data,
  ) {
    var coverFile = data["cover_file"] as String?;

    if (coverFile != null) {
      coverFile = "$applicationSupportDirectory/$coverFile";
    }

    return Album(
      id: data["id"] as int,
      name: data["name"] as String,
      artists: [],
      tracks: [],
      coverSignature: data["cover_signature"] as String,
      localCover: coverFile,
      isDownloaded: data["download_id"] != null,
      downloadTracks:
          data["partial_download"] != null && data["partial_download"] == 0,
    );
  }

  static loadAlbumTracks(
    Database db,
    String applicationSupportDirectory,
    Album album,
  ) async {
    album.tracks
      ..clear()
      ..addAll(
        (db.select('''
        SELECT * FROM tracks
        JOIN track_album ON tracks.id = track_album.track_id
        WHERE track_album.album_id = ?
      ''', [album.id])).map(TrackRepository.decodeTrack),
      );

    for (final track in album.tracks) {
      TrackRepository.loadTrackAlbums(db, applicationSupportDirectory, track);
      TrackRepository.loadTrackArtists(db, track);
    }
  }

  static loadAlbumArtists(Database db, Album album) {
    album.artists
      ..clear()
      ..addAll(
        (db.select('''
        SELECT * FROM artists
        JOIN album_artist ON artists.id = album_artist.artist_id
        WHERE album_artist.album_id = ?
	    	ORDER BY album_artist.artist_pos ASC
      ''', [album.id])).map(ArtistRepository.decodeArtist),
      );
  }

  Future<List<Album>> getAllAlbums() async {
    try {
      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final albums = (db.select("""
        SELECT albums.*, album_downloads.cover_file, album_downloads.album_id as download_id, album_downloads.partial_download,
          (
              SELECT MAX(tracks.date_added)
              FROM track_album
                      JOIN tracks ON tracks.id = track_album.track_id
              WHERE track_album.album_id = albums.id
          ) AS latest_track_created_at
        FROM albums
        LEFT JOIN album_downloads
          ON album_downloads.album_id = albums.id
        ORDER BY
          latest_track_created_at IS NOT NULL,
          latest_track_created_at DESC
        """))
          .map(
            (album) => decodeAlbum(applicationSupportDirectory, album),
          )
          .toList();

      for (final album in albums) {
        loadAlbumArtists(db, album);
      }

      return albums;
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<Album> getAlbumById(int id) async {
    try {
      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final album = (db.select("""
        SELECT albums.*, album_downloads.cover_file, album_downloads.album_id as download_id, album_downloads.partial_download
        FROM albums
        LEFT JOIN album_downloads
          ON album_downloads.album_id = albums.id
        WHERE id = ?
        """, [id]))
          .map(
            (album) => decodeAlbum(applicationSupportDirectory, album),
          )
          .firstOrNull;

      if (album == null) {
        throw AlbumNotFoundException();
      }

      loadAlbumTracks(db, applicationSupportDirectory, album);
      loadAlbumArtists(db, album);

      await playedTrackRepository.loadTrackHistoryIntoTracks(album.tracks);

      return album;
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<Album> changeAlbumCover(int id, File file) async {
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      final response = await AppApi().dio.put(
            "/album/$id/cover",
            data: formData,
          );

      await syncRepository.performSync();

      return getAlbumById(AlbumModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw AlbumNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Album> removeAlbumCover(int id) async {
    try {
      final response = await AppApi().dio.delete(
            "/album/$id/cover",
          );

      await syncRepository.performSync();

      return getAlbumById(AlbumModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw AlbumNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Album> createAlbum(Album album) async {
    try {
      final response = await AppApi().dio.post(
        "/album",
        data: {
          "name": album.name,
        },
      );

      await syncRepository.performSync();

      return getAlbumById(AlbumModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  setAlbumArtists(
    int albumId,
    List<Artist> artists,
  ) async {
    try {
      final response = await AppApi().dio.put(
        "/album/$albumId/artists",
        data: {
          "artist_ids": artists.map((artist) => artist.id).toList(),
        },
      );

      await syncRepository.performSync();

      return getAlbumById(AlbumModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw AlbumNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Album> deleteAlbumById(int albumId) async {
    try {
      final old = await getAlbumById(albumId);

      await AppApi().dio.delete(
            "/album/$albumId",
          );

      await syncRepository.performSync();

      return old;
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw AlbumNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final albumRepositoryProvider = Provider(
  (ref) => AlbumRepository(
    playedTrackRepository: ref.watch(
      playedTrackRepositoryProvider,
    ),
    syncRepository: ref.watch(
      syncRepositoryProvider,
    ),
    networkInfo: ref.watch(
      networkInfoProvider,
    ),
  ),
);
