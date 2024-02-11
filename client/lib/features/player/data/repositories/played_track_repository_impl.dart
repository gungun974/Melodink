import 'package:fpdart/fpdart.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/player/domain/entities/played_track.dart';
import 'package:melodink_client/features/player/domain/repositories/played_track_repository.dart';

class PlayedTrackRepositoryImpl implements PlayedTrackRepository {
  PlayedTrackRepositoryImpl();

  static PlayedTrack decodePlayedTrack(Map<String, Object?> data) {
    return PlayedTrack(
      id: data["id"] as int,
      trackId: data["track_id"] as int,
      startAt: DateTime.fromMillisecondsSinceEpoch(data["start_at"] as int),
      finishAt: DateTime.fromMillisecondsSinceEpoch(data["finish_at"] as int),
      beginAt: Duration(milliseconds: data["begin_at"] as int),
      endedAt: Duration(milliseconds: data["ended_at"] as int),
      shuffle: data["shuffle"] == 0 ? false : true,
      skipped: data["skipped"] == 0 ? false : true,
      trackEnded: data["track_ended"] == 0 ? false : true,
    );
  }

  Future<Either<Failure, PlayedTrack>> getPlayedTrackById(int id) async {
    final db = await DatabaseService.getDatabase();

    final data =
        await db.rawQuery("SELECT * FROM played_tracks WHERE id = ?", [id]);

    try {
      return Either.right(
        PlayedTrackRepositoryImpl.decodePlayedTrack(data.first),
      );
    } catch (_) {
      return Either.left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PlayedTrack>> addPlayedTrack({
    required int trackId,
    required DateTime startAt,
    required DateTime finishAt,
    required Duration beginAt,
    required Duration endedAt,
    required bool shuffle,
    required bool skipped,
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
      "skipped": skipped ? 1 : 0,
      "track_ended": trackEnded ? 1 : 0,
    });

    return getPlayedTrackById(id);
  }
}
