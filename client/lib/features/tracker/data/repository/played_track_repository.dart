import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/tracker/domain/entities/played_track.dart';
import 'package:sqflite/sqflite.dart';

class PlayedTrackRepository {
  static PlayedTrack decodePlayedTrack(Map<String, Object?> data) {
    return PlayedTrack(
      id: data["id"] as int,
      trackId: data["track_id"] as int,
      startAt: DateTime.fromMillisecondsSinceEpoch(data["start_at"] as int),
      finishAt: DateTime.fromMillisecondsSinceEpoch(data["finish_at"] as int),
      beginAt: Duration(milliseconds: data["begin_at"] as int),
      endedAt: Duration(milliseconds: data["ended_at"] as int),
      shuffle: data["shuffle"] == 0 ? false : true,
      trackEnded: data["track_ended"] == 0 ? false : true,
    );
  }

  Future<List<PlayedTrack>> getLastPlayedTracks() async {
    final db = await DatabaseService.getDatabase();

    final deviceId = await SettingsRepository().getDeviceId();

    try {
      final data = await db.rawQuery("""
        SELECT *
        FROM (
          SELECT *,
                LAG(track_id) OVER (
                  ORDER BY finish_at ASC
                ) AS prev_track_id
          FROM (
            SELECT id, track_id, start_at, finish_at, begin_at, ended_at, shuffle, track_ended
            FROM played_tracks

            UNION ALL

            SELECT id, track_id, start_at, finish_at, begin_at, ended_at, shuffle, track_ended
            FROM shared_played_tracks
            WHERE device_id != ?
          )
        ) AS ranked_tracks
        WHERE track_id != prev_track_id OR prev_track_id IS NULL;
      """, [deviceId]);

      return data.map(PlayedTrackRepository.decodePlayedTrack).toList();
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<PlayedTrack?> getLastFinishedPlayedTrackByTrackId(int trackId) async {
    final db = await DatabaseService.getDatabase();

    final deviceId = await SettingsRepository().getDeviceId();

    try {
      final data = await db.rawQuery("""
        SELECT * FROM (
            SELECT id, track_id, start_at, finish_at, begin_at, ended_at, shuffle, track_ended 
            FROM played_tracks 
            
            UNION ALL 
            
            SELECT id, track_id, start_at, finish_at, begin_at, ended_at, shuffle, track_ended 
            FROM shared_played_tracks
            WHERE device_id != ?
        ) 
        WHERE track_id = ? 
            AND track_ended = 1 
        ORDER BY finish_at DESC 
        LIMIT 1
        """, [deviceId, trackId]);

      if (data.firstOrNull == null) {
        return null;
      }

      return PlayedTrackRepository.decodePlayedTrack(data.first);
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<int> getTrackPlayedCountByTrackId(int trackId) async {
    final db = await DatabaseService.getDatabase();

    final deviceId = await SettingsRepository().getDeviceId();

    try {
      final data = await db.rawQuery("""
        SELECT (
            SELECT COUNT(*) FROM played_tracks WHERE track_id = ? AND track_ended = 1
        ) + (
            SELECT COUNT(*) FROM shared_played_tracks WHERE track_id = ? AND track_ended = 1 AND device_id != ?
        ) as total_plays;
        """, [trackId, trackId, deviceId]);

      if (data.firstOrNull == null) {
        return 0;
      }

      return Sqflite.firstIntValue(data)!;
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<PlayedTrack> getPlayedTrackById(int id) async {
    final db = await DatabaseService.getDatabase();

    final data =
        await db.rawQuery("SELECT * FROM played_tracks WHERE id = ?", [id]);

    try {
      return PlayedTrackRepository.decodePlayedTrack(data.first);
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<PlayedTrack> addPlayedTrack({
    required int trackId,
    required DateTime startAt,
    required DateTime finishAt,
    required Duration beginAt,
    required Duration endedAt,
    required bool shuffle,
    required bool trackEnded,
  }) async {
    final db = await DatabaseService.getDatabase();

    final id = await db.insert("played_tracks", {
      "track_id": trackId,
      "start_at": startAt.millisecondsSinceEpoch,
      "finish_at": finishAt.millisecondsSinceEpoch,
      "begin_at": beginAt.inMilliseconds,
      "ended_at": endedAt.inMilliseconds,
      "shuffle": shuffle ? 1 : 0,
      "track_ended": trackEnded ? 1 : 0,
    });

    return getPlayedTrackById(id);
  }
}

final playedTrackRepositoryProvider =
    Provider((ref) => PlayedTrackRepository());
