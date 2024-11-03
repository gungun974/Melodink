import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/tracker/data/models/shared_played_track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:sqflite/sqflite.dart';

class SyncSharedPlayedTrackRepository {
  Future<int> _getLastSharedId() async {
    final db = await DatabaseService.getDatabase();

    final List<Map<String, dynamic>> result = await db
        .rawQuery('SELECT MAX(id) as last_id FROM shared_played_tracks');

    if (result.isNotEmpty && result.first['last_id'] != null) {
      return result.first['last_id'] as int;
    }

    return 0;
  }

  Future<void> fetchSharedPlayedTracks() async {
    final db = await DatabaseService.getDatabase();

    final lastFetchedId = await _getLastSharedId();

    try {
      final response =
          await AppApi().dio.get("/sharedPlayedTrack/from/$lastFetchedId");

      final sharedPlayedTracks = (response.data as List)
          .map(
            (rawModel) => SharedPlayedTrackModel.fromJson(rawModel),
          )
          .toList();

      for (var sharedPlayedTrack in sharedPlayedTracks) {
        await db.insert(
          "shared_played_tracks",
          {
            "id": sharedPlayedTrack.id,
            "track_id": sharedPlayedTrack.trackId,
            "device_id": sharedPlayedTrack.deviceId,
            "start_at": sharedPlayedTrack.startAt.millisecondsSinceEpoch,
            "finish_at": sharedPlayedTrack.finishAt.millisecondsSinceEpoch,
            "begin_at": sharedPlayedTrack.beginAt.inMilliseconds,
            "ended_at": sharedPlayedTrack.endedAt.inMilliseconds,
            "shuffle": sharedPlayedTrack.shuffle ? 1 : 0,
            "track_ended": sharedPlayedTrack.trackEnded ? 1 : 0,
            "shared_at": sharedPlayedTrack.sharedAt.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      throw ServerUnknownException();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadNotSharedTracks() async {
    final db = await DatabaseService.getDatabase();

    final deviceId = await SettingsRepository().getDeviceId();

    final data = await db.rawQuery("""
      SELECT *
      FROM played_tracks
      WHERE shared = 0;
      """);

    final playedTracks =
        data.map(PlayedTrackRepository.decodePlayedTrack).toList();

    for (var playedTrack in playedTracks) {
      try {
        await AppApi().dio.post("/sharedPlayedTrack/upload", data: {
          "track_id": playedTrack.trackId,
          "device_id": deviceId,
          "start_at": playedTrack.startAt.toUtc().toIso8601String(),
          "finish_at": playedTrack.finishAt.toUtc().toIso8601String(),
          "begin_at": playedTrack.beginAt.inMilliseconds,
          "ended_at": playedTrack.endedAt.inMilliseconds,
          "shuffle": playedTrack.shuffle,
          "track_ended": playedTrack.trackEnded,
        });

        await db.update(
          "played_tracks",
          {
            "shared": 1,
          },
          where: "id = ?",
          whereArgs: [playedTrack.id],
        );
      } on DioException catch (e) {
        final response = e.response;
        if (response == null) {
          throw ServerTimeoutException();
        }

        throw ServerUnknownException();
      } catch (e) {
        rethrow;
      }
    }
  }
}

final syncSharedPlayedTrackRepositoryProvider =
    Provider((ref) => SyncSharedPlayedTrackRepository());
