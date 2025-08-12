import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/tracker/domain/entities/played_track.dart';
import 'package:melodink_client/features/tracker/domain/entities/track_history_info.dart';
import 'package:mutex/mutex.dart';

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
      trackDuration: Duration(milliseconds: data["track_duration"] as int),
    );
  }

  static TrackHistoryInfo decodeTrackHistoryInfo(Map<String, Object?> data) {
    final lastFinishedRaw = data["last_finished"] as int?;

    return TrackHistoryInfo(
      trackId: data["track_id"] as int,
      lastPlayedDate: lastFinishedRaw != null
          ? DateTime.fromMillisecondsSinceEpoch(lastFinishedRaw)
          : null,
      playedCount: data["played_count"] as int,
      computed: true,
    );
  }

  Future<List<PlayedTrack>> getLastPlayedTracks() async {
    final db = await DatabaseService.getDatabase();

    final deviceId = await SettingsRepository().getDeviceId();

    try {
      final data = db.select("""
        SELECT *
        FROM (
          SELECT *,
                LAG(track_id) OVER (
                  ORDER BY finish_at ASC
                ) AS prev_track_id
          FROM (
            SELECT id, track_id, start_at, finish_at, begin_at, ended_at, shuffle, track_ended, track_duration
            FROM played_tracks

            UNION ALL

            SELECT id, track_id, start_at, finish_at, begin_at, ended_at, shuffle, track_ended, track_duration
            FROM shared_played_tracks
            WHERE device_id != ?
          )
        ) AS ranked_tracks
        WHERE track_id != prev_track_id OR prev_track_id IS NULL
        ORDER BY finish_at DESC
        LIMIT 999;
      """, [deviceId]);

      return data.reversed
          .map(PlayedTrackRepository.decodePlayedTrack)
          .toList();
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<PlayedTrack?> getLastFinishedPlayedTrackByTrackId(int trackId) async {
    final db = await DatabaseService.getDatabase();

    final deviceId = await SettingsRepository().getDeviceId();

    try {
      final data = db.select("""
        WITH SegmentedTracks AS (SELECT *,
                                        CASE
                                            WHEN LEAD(begin_at, 1, begin_at)
                                                      OVER (PARTITION BY track_id, device_id ORDER BY finish_at) >=
                                                MIN(track_duration * 0.2, 5000.0) AND
                                                LEAD(track_id, 1, track_id)
                                                      OVER (PARTITION BY track_id, device_id ORDER BY finish_at) == track_id
                                                THEN 0
                                            ELSE 1
                                            END AS is_new_segment
                                FROM (SELECT id,
                                              track_id,
                                              start_at,
                                              finish_at,
                                              begin_at,
                                              ended_at,
                                              shuffle,
                                              track_ended,
                                              track_duration,
                                              ? as device_id
                                      FROM played_tracks

                                      UNION ALL

                                      SELECT id,
                                              track_id,
                                              start_at,
                                              finish_at,
                                              begin_at,
                                              ended_at,
                                              shuffle,
                                              track_ended,
                                              track_duration,
                                              device_id
                                      FROM shared_played_tracks
                                      WHERE device_id != ?)
                                WHERE track_id = ?),
            NumberedTracks AS (SELECT *,
                                      SUM(is_new_segment) OVER (PARTITION BY track_id, device_id ORDER BY finish_at DESC) AS segment_number
                                FROM SegmentedTracks)
        SELECT id,
              track_id,
              start_at,
              finish_at,
              begin_at,
              ended_at,
              shuffle,
              track_ended,
              track_duration
        FROM NumberedTracks
        GROUP BY track_id, device_id, segment_number
        HAVING SUM(ended_at - begin_at) > MIN(track_duration * 0.4, 30000.0)
        ORDER BY finish_at DESC
        LIMIT 1
        """, [deviceId, deviceId, trackId]);

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
      final data = db.select("""
        WITH SegmentedTracks AS (SELECT *,
                                        CASE
                                            WHEN LEAD(begin_at, 1, begin_at)
                                                      OVER (PARTITION BY track_id, device_id ORDER BY finish_at) >=
                                                MIN(track_duration * 0.2, 5000.0) AND
                                                LEAD(track_id, 1, track_id)
                                                      OVER (PARTITION BY track_id, device_id ORDER BY finish_at) == track_id
                                                THEN 0
                                            ELSE 1
                                            END AS is_new_segment
                                FROM (SELECT id,
                                              track_id,
                                              start_at,
                                              finish_at,
                                              begin_at,
                                              ended_at,
                                              shuffle,
                                              track_ended,
                                              track_duration,
                                              ? as device_id
                                      FROM played_tracks

                                      UNION ALL

                                      SELECT id,
                                              track_id,
                                              start_at,
                                              finish_at,
                                              begin_at,
                                              ended_at,
                                              shuffle,
                                              track_ended,
                                              track_duration,
                                              device_id
                                      FROM shared_played_tracks
                                      WHERE device_id != ?)
                                WHERE track_id = ?),
            NumberedTracks AS (SELECT *,
                                      SUM(is_new_segment) OVER (PARTITION BY track_id, device_id ORDER BY finish_at DESC) AS segment_number
                                FROM SegmentedTracks),
            FilteredTracks AS (SELECT track_id,
                                      device_id,
                                      segment_number,
                                      finish_at,
                                      SUM(ended_at - begin_at)
                                FROM NumberedTracks
                                GROUP BY track_id, device_id, segment_number
                                HAVING SUM(ended_at - begin_at) > MIN(track_duration * 0.4, 30000.0))
        SELECT COUNT(*)
        FROM FilteredTracks order by finish_at desc;
        """, [deviceId, deviceId, trackId]);

      if (data.firstOrNull == null) {
        return 0;
      }

      return data.first["COUNT(*)"] as int;
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<PlayedTrack> getPlayedTrackById(int id) async {
    final db = await DatabaseService.getDatabase();

    final data = db.select("SELECT * FROM played_tracks WHERE id = ?", [id]);

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
    required Duration trackDuration,
  }) async {
    final db = await DatabaseService.getDatabase();

    db.execute(
      '''
    INSERT INTO played_tracks (
      track_id,
      start_at,
      finish_at,
      begin_at,
      ended_at,
      shuffle,
      track_ended,
      track_duration
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        trackId,
        startAt.millisecondsSinceEpoch,
        finishAt.millisecondsSinceEpoch,
        beginAt.inMilliseconds,
        endedAt.inMilliseconds,
        shuffle ? 1 : 0,
        trackEnded ? 1 : 0,
        trackDuration.inMilliseconds,
      ],
    );

    final id = db.lastInsertRowId;

    await updateTrackHistoryInfoCache(trackId);

    return getPlayedTrackById(id);
  }

  Future<List<TrackHistoryInfo>> getMultipleTracksHistoryInfo(
    List<int> trackIds,
  ) async {
    final db = await DatabaseService.getDatabase();

    final data = db.select(
      'SELECT * FROM track_history_info_cache '
      'WHERE track_id IN (${List.filled(trackIds.length, '?').join(',')})',
      trackIds,
    );

    final List<TrackHistoryInfo> results = [];

    try {
      for (final row in data) {
        results.add(
          PlayedTrackRepository.decodeTrackHistoryInfo(row),
        );
      }
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }

    if (results.length != trackIds.length) {
      for (final trackId in trackIds) {
        final isResultMissing = !results.any(
          (result) => result.trackId == trackId,
        );

        if (isResultMissing) {
          results.add(
            TrackHistoryInfo(
              trackId: trackId,
              lastPlayedDate: null,
              playedCount: -1,
              computed: false,
            ),
          );

          updateTrackHistoryInfoCacheMutex.protect(() async {
            final data2 = db.select(
              'SELECT * FROM track_history_info_cache '
              'WHERE track_id = ?',
              [trackId],
            );

            if (data2.isEmpty) {
              await updateTrackHistoryInfoCache(trackId);
            }
          });
        }
      }
    }

    return results;
  }

  final updateTrackHistoryInfoCacheMutex = Mutex();

  Future<TrackHistoryInfo> getTrackHistoryInfo(int trackId) async {
    final db = await DatabaseService.getDatabase();

    final data = db.select(
        "SELECT * FROM track_history_info_cache WHERE track_id = ?", [trackId]);

    if (data.isEmpty) {
      return updateTrackHistoryInfoCache(trackId);
    }

    try {
      return PlayedTrackRepository.decodeTrackHistoryInfo(data.first);
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<TrackHistoryInfo> updateTrackHistoryInfoCache(int trackId) async {
    final db = await DatabaseService.getDatabase();

    final info = TrackHistoryInfo(
      trackId: trackId,
      lastPlayedDate:
          (await getLastFinishedPlayedTrackByTrackId(trackId))?.finishAt,
      playedCount: await getTrackPlayedCountByTrackId(trackId),
      computed: true,
    );

    try {
      db.execute(
        '''
    INSERT OR REPLACE INTO track_history_info_cache (
      track_id,
      last_finished,
      played_count,
      updated_at
    ) VALUES (?, ?, ?, ?)
    ''',
        [
          trackId,
          info.lastPlayedDate?.millisecondsSinceEpoch,
          info.playedCount,
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }

    // Should find a way to speed up computation. For now we tiny sleep to unstress async
    await Future.delayed(Duration(milliseconds: 1));

    return info;
  }

  Future<void> checkAndUpdateAllTrackHistoryCache() async {
    final db = await DatabaseService.getDatabase();

    final data = db.select("""
      SELECT track_history_info_cache.track_id
      FROM track_history_info_cache
              INNER JOIN (
          SELECT track_id, MAX(created_at) as last_created
          FROM (
                  SELECT track_id, created_at FROM played_tracks
                  UNION ALL
                  SELECT track_id, created_at FROM shared_played_tracks
        )
        GROUP BY track_id
      ) combined ON track_history_info_cache.track_id = combined.track_id
      WHERE track_history_info_cache.updated_at < combined.last_created OR track_history_info_cache.updated_at IS NULL;
      """);

    for (final row in data) {
      final trackId = row["track_id"] as int;

      await updateTrackHistoryInfoCache(trackId);
    }
  }

  loadTrackHistoryIntoTracks(List<Track> tracks) async {
    final infos = await getMultipleTracksHistoryInfo(
      tracks.map((track) => track.id).toList(),
    );

    for (final (index, track) in tracks.indexed) {
      final infoIndex = infos.indexWhere((info) => info.trackId == track.id);
      if (infoIndex >= 0) {
        tracks[index] = track.copyWith(
          historyInfo: () => infos[infoIndex],
        );
      }
    }
  }
}

final playedTrackRepositoryProvider = Provider(
  (ref) => PlayedTrackRepository(),
);
