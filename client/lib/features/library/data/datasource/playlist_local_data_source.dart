import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/data/models/minimal_track_model.dart';
import 'package:path_provider/path_provider.dart';

class PlaylistLocalDataSource {
  static Playlist decodeDownloadTrack(Map<String, Object?> data) {
    return Playlist(
      id: data["playlist_id"] as int,
      localCover: data["image_file"] as String?,
      name: data["name"] as String,
      description: data["description"] as String,
      tracks: (json.decode(data["tracks"] as String) as List)
          .map(
            (rawModel) => MinimalTrackModel.fromJson(rawModel).toMinimalTrack(),
          )
          .toList(),
      isDownloaded: true,
    );
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await DatabaseService.getDatabase();

    try {
      final data = await db.rawQuery("SELECT * FROM playlist_download");

      return data
          .map((downloadTrack) => decodeDownloadTrack(downloadTrack))
          .toList();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Playlist?> getPlaylistById(int id) async {
    final db = await DatabaseService.getDatabase();

    try {
      final data = await db.rawQuery(
          "SELECT * FROM playlist_download WHERE playlist_id = ?", [id]);

      final downloadTrack = data.firstOrNull;

      if (downloadTrack == null) {
        return null;
      }

      return decodeDownloadTrack(downloadTrack);
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<void> storePlaylist(Playlist playlist) async {
    final db = await DatabaseService.getDatabase();

    try {
      final savedPlaylist = await getPlaylistById(playlist.id);

      final downloadPath =
          "${(await getApplicationSupportDirectory()).path}/download-playlist/${playlist.id}";
      String? downloadImagePath = "$downloadPath-image";

      try {
        await AppApi().dio.download(
              "/playlist/${playlist.id}/cover",
              downloadImagePath,
            );
      } on DioException catch (e) {
        final response = e.response;
        if (response == null) {
          rethrow;
        }

        if (response.statusCode != 404) {
          rethrow;
        }

        downloadImagePath = null;
      }

      final body = {
        "image_file": downloadImagePath,
        "name": playlist.name,
        "description": playlist.description,
        "tracks": json.encode(
          playlist.tracks
              .map(
                (track) => MinimalTrackModel.fromMinimalTrack(track).toJson(),
              )
              .toList(),
        ),
      };

      if (savedPlaylist == null) {
        await db.insert("playlist_download", {
          "playlist_id": playlist.id,
          ...body,
        });
        return;
      }

      await db.update(
        "playlist_download",
        body,
        where: "playlist_id = ?",
        whereArgs: [playlist.id],
      );
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

  Future<void> deleteStoredPlaylist(int playlistId) async {
    final db = await DatabaseService.getDatabase();

    try {
      final savedPlaylist = await getPlaylistById(playlistId);

      if (savedPlaylist == null) {
        throw PlaylistNotFoundException();
      }

      await db.delete(
        "playlist_download",
        where: "playlist_id = ?",
        whereArgs: [playlistId],
      );
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final playlistLocalDataSourceProvider = Provider(
  (ref) => PlaylistLocalDataSource(),
);
