import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/helpers/split_id_to_path.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/data/models/minimal_track_model.dart';

class PlaylistLocalDataSource {
  static Playlist decodeDownloadTrack(
      Map<String, Object?> data, String applicationSupportDirectory) {
    final rawImageFile = data["image_file"] as String?;

    return Playlist(
      id: data["playlist_id"] as int,
      localCover: rawImageFile != null
          ? "$applicationSupportDirectory/$rawImageFile"
          : null,
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

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    try {
      final data = await db.rawQuery("SELECT * FROM playlist_download");

      return data
          .map((downloadTrack) =>
              decodeDownloadTrack(downloadTrack, applicationSupportDirectory))
          .toList();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Playlist?> getPlaylistById(int id) async {
    final db = await DatabaseService.getDatabase();

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    try {
      final data = await db.rawQuery(
          "SELECT * FROM playlist_download WHERE playlist_id = ?", [id]);

      final downloadTrack = data.firstOrNull;

      if (downloadTrack == null) {
        return null;
      }

      return decodeDownloadTrack(downloadTrack, applicationSupportDirectory);
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<void> storePlaylist(Playlist playlist) async {
    final db = await DatabaseService.getDatabase();

    try {
      final savedPlaylist = await getPlaylistById(playlist.id);

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final downloadPath = "/download-playlist/${splitIdToPath(playlist.id)}";
      String? downloadImagePath = "$downloadPath/image";

      try {
        await AppApi().dio.download(
              "/playlist/${playlist.id}/cover",
              "$applicationSupportDirectory/$downloadImagePath",
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

      if (downloadImagePath != null) {
        await FileImage(
          File("$applicationSupportDirectory/$downloadImagePath"),
        ).evict();

        PaintingBinding.instance.imageCache.clearLiveImages();
        WidgetsBinding.instance.reassembleApplication();
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

      final imageFile = savedPlaylist.localCover;

      if (imageFile != null) {
        try {
          await File(imageFile).delete();
        } catch (_) {}
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
