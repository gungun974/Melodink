import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/tracker/domain/entities/played_track.dart';
import 'package:melodink_client/features/tracker/domain/entities/track_history_info.dart';

class PlayedTrackRepository {
  static PlayedTrack decodePlayedTrack(Map<String, Object?> data) {
    return PlayedTrack(
      internalId: data["internal_id"] as int,
      serverId: data["server_id"] as int?,
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

  Future<List<Track>> getLastPlayedTracks() async {
    final db = await DatabaseService.getDatabase();

    try {
      final data = db.select("""
        SELECT t.*
        FROM tracks AS t
        JOIN (
          SELECT track_id, MAX(finish_at) as finish_at
          FROM validated_plays
          GROUP BY track_id
          ORDER BY finish_at DESC
          LIMIT 100
        ) AS r ON t.id = r.track_id
        ORDER BY r.finish_at DESC;
      """);

      final tracks = data.map(TrackRepository.decodeTrack).toList();

      for (final track in tracks) {
        TrackRepository.loadTrackArtists(db, track);
      }

      return tracks;
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<PlayedTrack?> getLastFinishedPlayedTrackByTrackId(int trackId) async {
    final db = await DatabaseService.getDatabase();
    final deviceId = await SettingsRepository().getDeviceId();

    try {
      final data = db.select(
        """
        SELECT pt.*
        FROM played_tracks pt
        INNER JOIN validated_plays vp 
          ON pt.track_id = vp.track_id 
          AND pt.finish_at = vp.finish_at
        WHERE vp.track_id = ?
          AND vp.device_id = ?
        ORDER BY vp.finish_at DESC
        LIMIT 1
      """,
        [trackId, deviceId],
      );

      if (data.isEmpty) return null;
      return decodePlayedTrack(data.first);
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<int> getTrackPlayedCountByTrackId(int trackId) async {
    final db = await DatabaseService.getDatabase();

    try {
      final data = db.select(
        "SELECT played_count FROM track_history_info WHERE track_id = ?",
        [trackId],
      );

      if (data.isEmpty) return 0;
      return data.first["played_count"] as int;
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<PlayedTrack> getPlayedTrackById(int id) async {
    final db = await DatabaseService.getDatabase();

    final data = db.select(
      "SELECT * FROM played_tracks WHERE internal_id = ?",
      [id],
    );

    try {
      return decodePlayedTrack(data.first);
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

    return getPlayedTrackById(id);
  }

  Future<void> removePlayedTrack(PlayedTrack playedTrack) async {
    final db = await DatabaseService.getDatabase();

    db.execute('BEGIN;');

    try {
      final data = db.select(
        "DELETE FROM played_tracks WHERE internal_id = ? RETURNING *",
        [playedTrack.internalId],
      );

      if (data.isNotEmpty) {
        PlayedTrack deletedPlayedTrack = decodePlayedTrack(data.first);

        if (deletedPlayedTrack.serverId != null) {
          db.execute(
            'INSERT OR REPLACE INTO deleted_played_tracks (id) VALUES (?)',
            [deletedPlayedTrack.serverId],
          );
        }
      }

      db.execute('COMMIT;');
    } catch (_) {
      db.execute("ROLLBACK;");
      rethrow;
    }
  }

  Future<List<TrackHistoryInfo>> getMultipleTracksHistoryInfo(
    List<int> trackIds,
  ) async {
    if (trackIds.isEmpty) return [];

    final db = await DatabaseService.getDatabase();

    final data = db.select(
      'SELECT * FROM track_history_info '
      'WHERE track_id IN (${List.filled(trackIds.length, '?').join(',')})',
      trackIds,
    );

    final results = <TrackHistoryInfo>[];

    try {
      for (final row in data) {
        results.add(decodeTrackHistoryInfo(row));
      }
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }

    for (final trackId in trackIds) {
      if (!results.any((r) => r.trackId == trackId)) {
        results.add(
          TrackHistoryInfo(
            trackId: trackId,
            lastPlayedDate: null,
            playedCount: 0,
            computed: true,
          ),
        );
      }
    }

    return results;
  }

  Future<TrackHistoryInfo> getTrackHistoryInfo(int trackId) async {
    final db = await DatabaseService.getDatabase();

    final data = db.select(
      "SELECT * FROM track_history_info WHERE track_id = ?",
      [trackId],
    );

    if (data.isEmpty) {
      return TrackHistoryInfo(
        trackId: trackId,
        lastPlayedDate: null,
        playedCount: 0,
        computed: true,
      );
    }

    try {
      return decodeTrackHistoryInfo(data.first);
    } catch (e) {
      databaseLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<void> loadTrackHistoryIntoTracks(List<Track> tracks) async {
    final infos = await getMultipleTracksHistoryInfo(
      tracks.map((track) => track.id).toList(),
    );

    for (final (index, track) in tracks.indexed) {
      final infoIndex = infos.indexWhere((info) => info.trackId == track.id);
      if (infoIndex >= 0) {
        tracks[index] = track.copyWith(historyInfo: () => infos[infoIndex]);
      }
    }
  }
}
