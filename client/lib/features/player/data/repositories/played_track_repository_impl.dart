import 'package:fpdart/fpdart.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/player/domain/entities/played_track.dart';
import 'package:melodink_client/features/player/domain/repositories/played_track_repository.dart';

class PlayedTrackRepositoryImpl implements PlayedTrackRepository {
  PlayedTrackRepositoryImpl();

  @override
  Future<Either<Failure, PlayedTrack>> addPlayedTrack(
      {required int trackId,
      required DateTime startAt,
      required DateTime finishAt,
      required Duration beginAt,
      required Duration endedAt,
      required bool shuffle,
      required bool skipped,
      required bool trackEnded}) async {
    print("------------------");
    print("trackId: $trackId");
    print("");
    print("startAt: $startAt");
    print("finishAt: $finishAt");
    print("");
    print("beginAt: $beginAt");
    print("endedAt: $endedAt");
    print("");
    print("shuffle: $shuffle");
    print("skipped: $skipped");
    print("");
    print("trackEnded: $trackEnded");
    print("------------------");

    return Either.left(ServerFailure());
  }
}
