import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/helpers/split_id_to_path.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/track/data/models/minimal_track_model.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';

class DownloadTrackRepository {
  static DownloadTrack decodeDownloadTrack(
      Map<String, Object?> data, String applicationSupportDirectory) {
    final rawAudioFile = data["audio_file"] as String;
    final rawImageFile = data["image_file"] as String?;

    return DownloadTrack(
      trackId: data["track_id"] as int,
      audioFile: "$applicationSupportDirectory/$rawAudioFile",
      imageFile: rawImageFile != null
          ? "$applicationSupportDirectory/$rawImageFile"
          : null,
      fileSignature: data["file_signature"] as String,
      coverSignature: data["cover_signature"] as String,
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

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final downloadTrack =
          decodeDownloadTrack(rawDownloadTrack, applicationSupportDirectory);

      final audioFile = File(downloadTrack.audioFile);

      if (!(await audioFile.exists())) {
        await deleteTrack(downloadTrack.trackId);

        return null;
      }

      return downloadTrack;
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<void> downloadOrUpdateTrack(int trackId) async {
    final db = await DatabaseService.getDatabase();

    try {
      final signatureResponse =
          await AppApi().dio.get<String>("/track/$trackId/signature");

      final coverSignatureResponse =
          await AppApi().dio.get<String>("/track/$trackId/cover/signature");

      final signature = signatureResponse.data;
      final coverSignature = coverSignatureResponse.data;

      if (signature == null) {
        throw ServerTimeoutException();
      }

      if (coverSignature == null) {
        throw ServerTimeoutException();
      }

      final downloadTrack = await getDownloadedTrackByTrackId(trackId);

      if (downloadTrack != null &&
          downloadTrack.fileSignature == signature &&
          downloadTrack.coverSignature == coverSignature) {
        return;
      }

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final downloadPath = "/download/${splitIdToPath(trackId)}";

      final downloadAudioPath = "$downloadPath/audio";
      String? downloadImagePath = "$downloadPath/image-$coverSignature";

      if (downloadTrack?.fileSignature != signature) {
        await AppApi().dio.download(
              "/track/$trackId/audio",
              "$applicationSupportDirectory/$downloadAudioPath",
            );
      }

      if (downloadTrack?.coverSignature != coverSignature) {
        try {
          await AppApi().dio.download(
                "/track/$trackId/cover",
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

        if (downloadTrack?.imageFile != null) {
          try {
            await File(downloadTrack!.imageFile!).delete();
          } catch (_) {}
        }
      }

      if (downloadTrack == null) {
        await db.insert("track_download", {
          "track_id": trackId,
          "audio_file": downloadAudioPath,
          "image_file": downloadImagePath,
          "file_signature": signature,
          "cover_signature": coverSignature,
        });
        return;
      }

      await db.rawUpdate(
          "UPDATE track_download SET file_signature = ?, cover_signature = ?, image_file = ? WHERE track_id = ?",
          [signature, coverSignature, downloadImagePath, trackId]);
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
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<List<DownloadTrack>> getOrphanTracks() async {
    final db = await DatabaseService.getDatabase();

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    try {
      final albumTracksData =
          await db.rawQuery("SELECT tracks FROM album_download");

      final playlistTracksData =
          await db.rawQuery("SELECT tracks FROM playlist_download");

      final trackIds = [
        ...albumTracksData
            .map((data) => (json.decode(data["tracks"] as String) as List)
                .map(
                  (rawModel) => MinimalTrackModel.fromJson(rawModel).id,
                )
                .toList())
            .expand((i) => i),
        ...playlistTracksData
            .map((data) => (json.decode(data["tracks"] as String) as List)
                .map(
                  (rawModel) => MinimalTrackModel.fromJson(rawModel).id,
                )
                .toList())
            .expand((i) => i)
      ];

      final orphansData = await db.rawQuery(
        "SELECT * FROM track_download WHERE track_id NOT IN (${trackIds.join(",")})",
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

        final imageFile = orphan.imageFile;

        if (imageFile != null) {
          try {
            await File(imageFile).delete();
          } catch (_) {}
        }

        await db.delete(
          "track_download",
          where: "track_id = ?",
          whereArgs: [orphan.trackId],
        );
      }
    } catch (e) {
      mainLogger.e(e);
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
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final downloadTrackRepositoryProvider =
    Provider((ref) => DownloadTrackRepository());
