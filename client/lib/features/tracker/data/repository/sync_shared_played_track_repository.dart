import 'package:dio/dio.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/tracker/data/models/shared_played_track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';

class SyncSharedPlayedTrackRepository {
  Future<int> _getLastSharedId() async {
    final db = await DatabaseService.getDatabase();

    final List<Map<String, dynamic>> result = db.select(
      'SELECT MAX(id) as last_id FROM shared_played_tracks',
    );

    if (result.isNotEmpty && result.first['last_id'] != null) {
      return result.first['last_id'] as int;
    }

    return 0;
  }

  Future<void> fetchSharedPlayedTracks() async {
    final db = await DatabaseService.getDatabase();

    final lastFetchedId = await _getLastSharedId();

    try {
      final response = await AppApi().dio.get(
        "/sharedPlayedTrack/from/$lastFetchedId",
      );

      final sharedPlayedTracks = (response.data as List)
          .map((rawModel) => SharedPlayedTrackModel.fromJson(rawModel))
          .toList();

      if (sharedPlayedTracks.isEmpty) {
        return;
      }

      const chunkSize = 75;

      final insertBatch = db.prepare('''
    INSERT OR REPLACE INTO shared_played_tracks (
      id,
      internal_device_id,
      track_id,
      device_id,
      start_at,
      finish_at,
      begin_at,
      ended_at,
      shuffle,
      track_ended,
      track_duration,
      shared_at
    ) VALUES ${List.filled(chunkSize, "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)").join(', ')}
    ''');

      for (var i = 0; i < sharedPlayedTracks.length; i += chunkSize) {
        if ((i + chunkSize < sharedPlayedTracks.length)) {
          final chunk = sharedPlayedTracks.sublist(i, i + chunkSize);

          insertBatch.execute(
            chunk
                .map(
                  (sharedPlayedTrack) => [
                    sharedPlayedTrack.id,
                    sharedPlayedTrack.internalDeviceId,
                    sharedPlayedTrack.trackId,
                    sharedPlayedTrack.deviceId,
                    sharedPlayedTrack.startAt.millisecondsSinceEpoch,
                    sharedPlayedTrack.finishAt.millisecondsSinceEpoch,
                    sharedPlayedTrack.beginAt.inMilliseconds,
                    sharedPlayedTrack.endedAt.inMilliseconds,
                    sharedPlayedTrack.shuffle ? 1 : 0,
                    sharedPlayedTrack.trackEnded ? 1 : 0,
                    sharedPlayedTrack.trackDuration.inMilliseconds,
                    sharedPlayedTrack.sharedAt.millisecondsSinceEpoch,
                  ],
                )
                .expand((x) => x)
                .toList(),
          );
        } else {
          final chunk = sharedPlayedTracks.sublist(
            i,
            sharedPlayedTracks.length,
          );

          final insertBatchLast = db.prepare('''
    INSERT OR REPLACE INTO shared_played_tracks (
      id,
      internal_device_id,
      track_id,
      device_id,
      start_at,
      finish_at,
      begin_at,
      ended_at,
      shuffle,
      track_ended,
      track_duration,
      shared_at
    ) VALUES ${List.filled(chunk.length, "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)").join(', ')}
    ''');

          insertBatchLast.execute(
            chunk
                .map(
                  (sharedPlayedTrack) => [
                    sharedPlayedTrack.id,
                    sharedPlayedTrack.internalDeviceId,
                    sharedPlayedTrack.trackId,
                    sharedPlayedTrack.deviceId,
                    sharedPlayedTrack.startAt.millisecondsSinceEpoch,
                    sharedPlayedTrack.finishAt.millisecondsSinceEpoch,
                    sharedPlayedTrack.beginAt.inMilliseconds,
                    sharedPlayedTrack.endedAt.inMilliseconds,
                    sharedPlayedTrack.shuffle ? 1 : 0,
                    sharedPlayedTrack.trackEnded ? 1 : 0,
                    sharedPlayedTrack.trackDuration.inMilliseconds,
                    sharedPlayedTrack.sharedAt.millisecondsSinceEpoch,
                  ],
                )
                .expand((x) => x)
                .toList(),
          );

          insertBatchLast.dispose();
        }
        if (i % 100 == 0) {
          await Future.delayed(Duration(milliseconds: 1));
        }
      }

      insertBatch.dispose();
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

    final data = db.select(
      """
      SELECT *
      FROM played_tracks
      WHERE id NOT IN (
          SELECT internal_device_id 
          FROM shared_played_tracks 
          WHERE device_id = ?
      )
      """,
      [deviceId],
    );

    final playedTracks = data
        .map(PlayedTrackRepository.decodePlayedTrack)
        .toList();

    for (var playedTrack in playedTracks) {
      try {
        await AppApi().dio.post(
          "/sharedPlayedTrack/upload",
          data: {
            "internal_device_id": playedTrack.id,
            "track_id": playedTrack.trackId,
            "device_id": deviceId,
            "start_at": playedTrack.startAt.toUtc().toIso8601String(),
            "finish_at": playedTrack.finishAt.toUtc().toIso8601String(),
            "begin_at": playedTrack.beginAt.inMilliseconds,
            "ended_at": playedTrack.endedAt.inMilliseconds,
            "track_duration": playedTrack.trackDuration.inMilliseconds,
            "shuffle": playedTrack.shuffle,
            "track_ended": playedTrack.trackEnded,
          },
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
