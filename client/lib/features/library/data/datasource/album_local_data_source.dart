import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/helpers/split_hash_to_path.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/library/data/models/artist_model.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/data/models/minimal_track_model.dart';

class AlbumLocalDataSource {
  static Album decodeDownloadTrack(
      Map<String, Object?> data, String applicationSupportDirectory) {
    final rawImageFile = data["image_file"] as String?;

    return Album(
      id: data["album_id"] as String,
      localCover: rawImageFile != null
          ? "$applicationSupportDirectory/$rawImageFile"
          : null,
      name: data["name"] as String,
      albumArtists: (json.decode(data["album_artists"] as String) as List)
          .map(
            (rawModel) =>
                MinimalArtistModel.fromJson(rawModel).toMinimalArtist(),
          )
          .toList(),
      tracks: (json.decode(data["tracks"] as String) as List)
          .map(
            (rawModel) => MinimalTrackModel.fromJson(rawModel).toMinimalTrack(),
          )
          .toList(),
      isDownloaded: true,
    );
  }

  Future<List<Album>> getAllAlbums() async {
    final db = await DatabaseService.getDatabase();

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    try {
      final data = await db.rawQuery("SELECT * FROM album_download");

      return data
          .map((downloadTrack) =>
              decodeDownloadTrack(downloadTrack, applicationSupportDirectory))
          .toList();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Album?> getAlbumById(String id) async {
    final db = await DatabaseService.getDatabase();

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    try {
      final data = await db
          .rawQuery("SELECT * FROM album_download WHERE album_id = ?", [id]);

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

  Future<void> storeAlbum(Album album) async {
    final db = await DatabaseService.getDatabase();

    try {
      final savedAlbum = await getAlbumById(album.id);

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final downloadPath = "/download-album/${splitHashToPath(album.id)}";
      String? downloadImagePath = "$downloadPath/image";

      try {
        await AppApi().dio.download(
              "/album/${album.id}/cover",
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

      final body = {
        "image_file": downloadImagePath,
        "name": album.name,
        "album_artists": json.encode(
          album.albumArtists
              .map(
                (artist) =>
                    MinimalArtistModel.fromMinimalArtist(artist).toJson(),
              )
              .toList(),
        ),
        "tracks": json.encode(
          album.tracks
              .map(
                (track) => MinimalTrackModel.fromMinimalTrack(track).toJson(),
              )
              .toList(),
        ),
      };

      if (savedAlbum == null) {
        await db.insert("album_download", {
          "album_id": album.id,
          ...body,
        });
        return;
      }

      await db.update(
        "album_download",
        body,
        where: "album_id = ?",
        whereArgs: [album.id],
      );
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

  Future<void> deleteStoredAlbum(String albumId) async {
    final db = await DatabaseService.getDatabase();

    try {
      final savedAlbum = await getAlbumById(albumId);

      if (savedAlbum == null) {
        throw AlbumNotFoundException();
      }

      final imageFile = savedAlbum.localCover;

      if (imageFile != null) {
        try {
          await File(imageFile).delete();
        } catch (_) {}
      }

      await db.delete(
        "album_download",
        where: "album_id = ?",
        whereArgs: [albumId],
      );
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final albumLocalDataSourceProvider = Provider(
  (ref) => AlbumLocalDataSource(),
);
