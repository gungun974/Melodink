import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/core/usecases/usecase.dart';
import 'package:melodink_client/features/player/domain/entities/played_track.dart';
import 'package:melodink_client/features/player/domain/repositories/played_track_repository.dart';

class RegisterPlayedTrackParams extends Equatable {
  final int trackId;
  final DateTime startAt;
  final DateTime finishAt;
  final Duration beginAt;
  final Duration endedAt;
  final bool shuffle;
  final bool skipped;
  final bool trackEnded;

  const RegisterPlayedTrackParams({
    required this.trackId,
    required this.startAt,
    required this.finishAt,
    required this.beginAt,
    required this.endedAt,
    required this.shuffle,
    required this.skipped,
    required this.trackEnded,
  });

  @override
  List<Object> get props => [
        trackId,
        startAt,
        finishAt,
        beginAt,
        endedAt,
        shuffle,
        skipped,
        trackEnded,
      ];
}

class RegisterPlayedTrack
    implements UseCase<PlayedTrack, RegisterPlayedTrackParams> {
  final PlayedTrackRepository repository;

  RegisterPlayedTrack(this.repository);

  @override
  Future<Either<Failure, PlayedTrack>> call(params) async {
    return await repository.addPlayedTrack(
      trackId: params.trackId,
      startAt: params.startAt,
      finishAt: params.finishAt,
      beginAt: params.beginAt,
      endedAt: params.endedAt,
      shuffle: params.shuffle,
      skipped: params.skipped,
      trackEnded: params.trackEnded,
    );
  }
}
