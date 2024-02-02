import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/core/usecases/usecase.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';

class Params extends Equatable {
  final int trackId;

  const Params({required this.trackId});

  @override
  List<Object> get props => [trackId];
}

class FetchAudioStream implements UseCase<String, Params> {
  final TrackRepository repository;

  FetchAudioStream(this.repository);

  @override
  Future<Either<Failure, String>> call(params) async {
    return await repository.fetchAudioStream(params.trackId);
  }
}
