import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/features/track/data/models/track_model.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:path_provider/path_provider.dart';

class TrackNotFoundException implements Exception {}

class DownloadTrackRepository {
  static DownloadTrack decodeDownloadTrack(Map<String, Object?> data) {
    return DownloadTrack(
      trackId: data["track_id"] as int,
      audioFile: data["audio_file"] as String,
      imageFile: data["image_file"] as String,
      fileSignature: data["file_signature"] as String,
    );
  }

  Future<DownloadTrack?> getDownloadedTrackByTrackId(int trackId) async {
    final db = await DatabaseService.getDatabase();

    try {
      final data = await db.rawQuery(
          "SELECT * FROM track_download WHERE track_id = ?", [trackId]);

      final rawDownloadTrack = data.firstOrNull;

      if (rawDownloadTrack == null) {
        return null;
      }

      final downloadTrack = decodeDownloadTrack(rawDownloadTrack);

      final audioFile = File(downloadTrack.audioFile);

      if (!(await audioFile.exists())) {
        await deleteTrack(downloadTrack.trackId);

        return null;
      }

      return downloadTrack;
    } catch (e) {
      print(e);
      throw ServerUnknownException();
    }
  }

  Future<void> downloadOrUpdateTrack(int trackId) async {
    final db = await DatabaseService.getDatabase();

    try {
      final signatureResponse =
          await AppApi().dio.get<String>("/track/$trackId/signature");

      final signature = signatureResponse.data;

      if (signature == null) {
        throw ServerTimeoutException();
      }

      final downloadTrack = await getDownloadedTrackByTrackId(trackId);

      if (downloadTrack != null && downloadTrack.fileSignature == signature) {
        return;
      }

      final downloadPath =
          "${(await getApplicationSupportDirectory()).path}/download/$trackId";
      final downloadAudioPath = "$downloadPath-audio";
      final downloadImagePath = "$downloadPath-image";

      await AppApi().dio.download(
            "/track/$trackId/audio",
            downloadAudioPath,
          );

      await AppApi().dio.download(
            "/track/$trackId/cover",
            downloadImagePath,
          );

      if (downloadTrack == null) {
        await db.insert("track_download", {
          "track_id": trackId,
          "audio_file": downloadAudioPath,
          "image_file": downloadImagePath,
          "file_signature": signature,
        });
        return;
      }

      await db.rawUpdate(
          "UPDATE track_download SET file_signature = ? WHERE track_id = ?",
          [signature, trackId]);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      print(e);
      throw ServerUnknownException();
    }
  }

  Future<List<DownloadTrack>> getOrphanTracks() async {
    final db = await DatabaseService.getDatabase();

    try {
      final albumTracksData =
          await db.rawQuery("SELECT tracks FROM album_download");

      final trackIds = albumTracksData
          .map((data) => (json.decode(data["tracks"] as String) as List)
              .map(
                (rawModel) => MinimalTrackModel.fromJson(rawModel).id,
              )
              .toList())
          .expand((i) => i)
          .toList();

      final orphansData = await db.rawQuery(
        "SELECT * FROM track_download WHERE track_id NOT IN (${trackIds.join(",")})",
      );

      final orphans =
          orphansData.map((data) => decodeDownloadTrack(data)).toList();

      return orphans;
    } catch (e) {
      print(e);
      throw ServerUnknownException();
    }
  }

  Future<void> deleteOrphanTracks(int? currentPlayerTrack) async {
    final db = await DatabaseService.getDatabase();

    final orphans = await getOrphanTracks();

    try {
      for (var orphan in orphans) {
        if (currentPlayerTrack == orphan.trackId) {
          continue;
        }

        try {
          await File(orphan.audioFile).delete();
        } catch (_) {}

        try {
          await File(orphan.imageFile).delete();
        } catch (_) {}

        await db.delete(
          "track_download",
          where: "track_id = ?",
          whereArgs: [orphan.trackId],
        );
      }
    } catch (e) {
      print(e);
      throw ServerUnknownException();
    }
  }

  Future<void> deleteTrack(int trackId) async {
    final db = await DatabaseService.getDatabase();

    try {
      await db.delete(
        "track_download",
        where: "track_id = ?",
        whereArgs: [trackId],
      );
    } catch (e) {
      print(e);
      throw ServerUnknownException();
    }
  }
}

final downloadTrackRepositoryProvider =
    Provider((ref) => DownloadTrackRepository());
