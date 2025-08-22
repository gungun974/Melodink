import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/sync/data/models/playlist_model.dart';
import 'package:melodink_client/features/sync/data/repository/sync_repository.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class PlaylistNotFoundException implements Exception {}

class PlaylistRepository {
  final PlayedTrackRepository playedTrackRepository;
  final SyncRepository syncRepository;

  final NetworkInfo networkInfo;

  PlaylistRepository({
    required this.playedTrackRepository,
    required this.syncRepository,
    required this.networkInfo,
  });

  static Playlist decodePlaylist(
    String applicationSupportDirectory,
    Map<String, Object?> data,
  ) {
    var coverFile = data["cover_file"] as String?;

    if (coverFile != null) {
      coverFile = "$applicationSupportDirectory/$coverFile";
    }

    return Playlist(
      id: data["id"] as int,
      name: data["name"] as String,
      description: data["description"] as String,
      tracks: [],
      coverSignature: data["cover_signature"] as String,
      localCover: coverFile,
      isDownloaded: data["download_id"] != null,
    );
  }

  static void loadPlaylistTracks(
    Database db,
    String applicationSupportDirectory,
    Playlist playlist,
  ) {
    final trackIds = List<int>.from(
      jsonDecode(
        (db.select(
              '''
        SELECT tracks FROM playlists
        WHERE id = ?
      ''',
              [playlist.id],
            )).first["tracks"]
            as String,
      ),
    );

    if (trackIds.isEmpty) {
      return;
    }

    final placeholders = List.filled(trackIds.length, '?').join(', ');

    final tracks = db
        .select('''
        SELECT * FROM tracks
        WHERE id IN ($placeholders)
        ORDER BY CASE id
            ${trackIds.indexed.map((entry) => "WHEN ${entry.$2} THEN ${entry.$1}").join(" ")}
        END;
      ''', trackIds)
        .map(TrackRepository.decodeTrack)
        .toList();

    playlist.tracks
      ..clear
      ..addAll(tracks);

    for (final track in playlist.tracks) {
      TrackRepository.loadTrackAlbums(db, applicationSupportDirectory, track);
      TrackRepository.loadTrackArtists(db, track);
    }
  }

  Future<List<Playlist>> getAllPlaylists() async {
    try {
      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final playlists =
          (db.select("""
        SELECT playlists.*, playlist_downloads.cover_file, playlist_downloads.playlist_id as download_id
        FROM playlists
        LEFT JOIN playlist_downloads
          ON playlist_downloads.playlist_id = playlists.id
        """))
              .map(
                (playlist) =>
                    decodePlaylist(applicationSupportDirectory, playlist),
              )
              .toList();

      return playlists;
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<Playlist> getPlaylistById(int id) async {
    try {
      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final playlist =
          (db.select(
                """
        SELECT playlists.*, playlist_downloads.cover_file, playlist_downloads.playlist_id as download_id
        FROM playlists
        LEFT JOIN playlist_downloads
          ON playlist_downloads.playlist_id = playlists.id
        WHERE id = ?
        """,
                [id],
              ))
              .map(
                (playlist) =>
                    decodePlaylist(applicationSupportDirectory, playlist),
              )
              .firstOrNull;

      if (playlist == null) {
        throw PlaylistNotFoundException();
      }

      loadPlaylistTracks(db, applicationSupportDirectory, playlist);

      await playedTrackRepository.loadTrackHistoryIntoTracks(playlist.tracks);

      return playlist;
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<Playlist> addPlaylistTracks(int playlistId, List<Track> tracks) async {
    final playlist = await getPlaylistById(playlistId);

    return await setPlaylistTracks(playlist.id, [
      ...playlist.tracks,
      ...tracks,
    ]);
  }

  Future<Playlist> setPlaylistTracks(int playlistId, List<Track> tracks) async {
    try {
      final response = await AppApi().dio.put(
        "/playlist/$playlistId/tracks",
        data: {"track_ids": tracks.map((track) => track.id).toList()},
      );

      await syncRepository.performSync();

      return getPlaylistById(PlaylistModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw PlaylistNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Playlist> createPlaylist(Playlist playlist) async {
    try {
      final response = await AppApi().dio.post(
        "/playlist",
        data: {"name": playlist.name, "description": playlist.description},
      );

      await syncRepository.performSync();

      return getPlaylistById(PlaylistModel.fromJson(response.data).id);
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

  Future<Playlist> duplicatePlaylist(int playlistId) async {
    try {
      final response = await AppApi().dio.post(
        "/playlist/$playlistId/duplicate",
      );

      await syncRepository.performSync();

      return getPlaylistById(PlaylistModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw PlaylistNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Playlist> savePlaylist(Playlist playlist) async {
    try {
      final response = await AppApi().dio.put(
        "/playlist/${playlist.id}",
        data: {"name": playlist.name, "description": playlist.description},
      );

      await syncRepository.performSync();

      return getPlaylistById(PlaylistModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw PlaylistNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Playlist> changePlaylistCover(int id, File file) async {
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      final response = await AppApi().dio.put(
        "/playlist/$id/cover",
        data: formData,
      );

      await syncRepository.performSync();

      return getPlaylistById(PlaylistModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw PlaylistNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Playlist> removePlaylistCover(int id) async {
    try {
      final response = await AppApi().dio.delete("/playlist/$id/cover");

      await syncRepository.performSync();

      return getPlaylistById(PlaylistModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw PlaylistNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Playlist> deletePlaylistById(int playlistId) async {
    try {
      final old = await getPlaylistById(playlistId);

      await AppApi().dio.delete("/playlist/$playlistId");

      await syncRepository.performSync();

      return old;
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw PlaylistNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}
