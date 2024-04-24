import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/player/domain/entities/played_track.dart';

abstract class PlayedTrackRepository {
  Future<Result<PlayedTrack>> addPlayedTrack({
    required int trackId,
    required DateTime startAt,
    required DateTime finishAt,
    required Duration beginAt,
    required Duration endedAt,
    required bool shuffle,
    required bool skipped,
    required bool trackEnded,
  });
}
