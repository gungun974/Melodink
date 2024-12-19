import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
      downloadTracks: data["download_tracks"] == 1,
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

  Future<void> storeAlbum(Album album, bool shouldDownloadTracks) async {
    final db = await DatabaseService.getDatabase();

    try {
      final savedAlbum = await getAlbumById(album.id);

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final downloadPath = "/download-album/${splitHashToPath(album.id)}";
      String? downloadImagePath;

      try {
        final signatureResponse = await AppApi()
            .dio
            .get<String>("/album/${album.id}/cover/signature");

        final signature = signatureResponse.data;

        if (signature != null && signature.trim().isNotEmpty) {
          downloadImagePath = "$downloadPath/image-$signature";

          if (!(await File("$applicationSupportDirectory/$downloadImagePath")
              .exists())) {
            await AppApi().dio.download(
                  "/album/${album.id}/cover",
                  "$applicationSupportDirectory/$downloadImagePath",
                );
          }

          if (savedAlbum?.localCover != null &&
              savedAlbum!.localCover !=
                  "$applicationSupportDirectory/$downloadImagePath") {
            try {
              await File(savedAlbum.localCover!).delete();
            } catch (_) {}
          }
        } else if (savedAlbum?.localCover != null) {
          try {
            await File(savedAlbum!.localCover!).delete();
          } catch (_) {}
        }
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
        if (shouldDownloadTracks) "download_tracks": 1,
      };

      if (savedAlbum == null) {
        await db.insert("album_download", {
          "album_id": album.id,
          ...body,
          "download_tracks": shouldDownloadTracks ? 1 : 0,
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
    } on AlbumNotFoundException {
      rethrow;
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<List<Album>> getOrphanAlbums() async {
    final db = await DatabaseService.getDatabase();

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    try {
      final playlistTracksData =
          await db.rawQuery("SELECT tracks FROM playlist_download");

      final albumIds = playlistTracksData
          .map((data) => (json.decode(data["tracks"] as String) as List)
              .map(
                (rawModel) =>
                    "'${MinimalTrackModel.fromJson(rawModel).albumId}'",
              )
              .toSet())
          .expand((i) => i);

      final orphansData = await db.rawQuery(
        "SELECT * FROM album_download WHERE download_tracks = 0 AND album_id NOT IN (${albumIds.join(",")})",
      );

      final orphans = orphansData
          .map((data) => decodeDownloadTrack(data, applicationSupportDirectory))
          .toList();

      return orphans;
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<void> deleteOrphanAlbums() async {
    final orphans = await getOrphanAlbums();

    try {
      for (var orphan in orphans) {
        await deleteStoredAlbum(orphan.id);
      }
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final albumLocalDataSourceProvider = Provider(
  (ref) => AlbumLocalDataSource(),
);
