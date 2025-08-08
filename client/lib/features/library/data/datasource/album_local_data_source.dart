import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/library/data/models/artist_model.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/data/models/minimal_track_model.dart';

class AlbumLocalDataSource {
  static Album decodeDownloadTrack(
      Map<String, Object?> data, String applicationSupportDirectory) {
    final rawImageFile = data["image_file"] as String?;

    final tracks = (json.decode(data["tracks"] as String) as List)
        .map(
          (rawModel) => MinimalTrackModel.fromJson(rawModel).toMinimalTrack(),
        )
        .toList();

    return Album(
      id: int.parse(data["album_id"] as String),
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
      tracks: tracks,
      isDownloaded: true,
      downloadTracks: data["download_tracks"] == 1,
      coverSignature: data["cover_signature"] as String,
      lastTrackDateAdded: tracks.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : tracks
              .reduce((a, b) => a.dateAdded.isAfter(b.dateAdded) ? a : b)
              .dateAdded,
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

  Future<Album?> getAlbumById(int id) async {
    final db = await DatabaseService.getDatabase();

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    try {
      final data = await db.rawQuery(
          "SELECT * FROM album_download WHERE album_id = ?", [id.toString()]);

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

  Future<void> storeAlbum(
    Album album,
    bool shouldDownloadTracks, {
    String? customSignature,
  }) async {
    final db = await DatabaseService.getDatabase();

    try {
      final savedAlbum = await getAlbumById(album.id);

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final downloadPath = "/download-album/${album.id}";
      String? downloadImagePath;

      late final String? coverSignature;

      try {
        if (customSignature != null) {
          coverSignature = customSignature;
        } else {
          final signatureResponse = await AppApi()
              .dio
              .get<String>("/album/${album.id}/cover/signature");

          coverSignature = signatureResponse.data;
        }

        downloadImagePath = "$downloadPath/image-$coverSignature";

        if (savedAlbum?.coverSignature != coverSignature) {
          await AppApi().dio.download(
                "/album/${album.id}/cover",
                "$applicationSupportDirectory/$downloadImagePath",
              );

          if (savedAlbum?.localCover != null) {
            try {
              await File(savedAlbum!.localCover!).delete();
            } catch (_) {}
          }
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

      if (savedAlbum?.localCover != null && downloadImagePath == null) {
        try {
          await File(savedAlbum!.localCover!).delete();
        } catch (_) {}
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
        "cover_signature": coverSignature,
      };

      if (savedAlbum == null) {
        await db.insert("album_download", {
          "album_id": album.id.toString(),
          ...body,
          "download_tracks": shouldDownloadTracks ? 1 : 0,
        });
        return;
      }

      await db.update(
        "album_download",
        body,
        where: "album_id = ?",
        whereArgs: [album.id.toString()],
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

  Future<void> storeAlbums(
    List<Album> albums,
    bool shouldDownloadTracks,
    Map<int, String> signatures, [
    StreamController<double>? streamController,
  ]) async {
    final db = await DatabaseService.getDatabase();

    try {
      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final savedAlbums = await getAllAlbums();

      for (final indexed in albums.indexed) {
        final album = indexed.$2;

        await Future.delayed(const Duration(milliseconds: 10));

        streamController?.add(indexed.$1 / albums.length);

        final index = savedAlbums.indexWhere(
          (savedAlbum) => savedAlbum.id == album.id,
        );

        final savedAlbum = index != -1 ? savedAlbums[index] : null;

        final customSignature = signatures[album.id];

        final downloadPath = "/download-album/${album.id}";
        String? downloadImagePath;

        late final String? coverSignature;

        try {
          if (customSignature != null) {
            coverSignature = customSignature;
          } else {
            final signatureResponse = await AppApi()
                .dio
                .get<String>("/album/${album.id}/cover/signature");

            coverSignature = signatureResponse.data;
          }

          downloadImagePath = "$downloadPath/image-$coverSignature";

          if (savedAlbum?.coverSignature != coverSignature) {
            await AppApi().dio.download(
                  "/album/${album.id}/cover",
                  "$applicationSupportDirectory/$downloadImagePath",
                );

            if (savedAlbum?.localCover != null) {
              try {
                await File(savedAlbum!.localCover!).delete();
              } catch (_) {}
            }
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

        if (savedAlbum?.localCover != null && downloadImagePath == null) {
          try {
            await File(savedAlbum!.localCover!).delete();
          } catch (_) {}
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
          "cover_signature": coverSignature,
        };

        if (savedAlbum == null) {
          await db.insert("album_download", {
            "album_id": album.id.toString(),
            ...body,
            "download_tracks": shouldDownloadTracks ? 1 : 0,
          });
          continue;
        }

        await db.update(
          "album_download",
          body,
          where: "album_id = ?",
          whereArgs: [album.id.toString()],
        );
      }
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

  Future<void> deleteStoredAlbum(int albumId) async {
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
        whereArgs: [albumId.toString()],
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
