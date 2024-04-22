import 'package:fpdart/fpdart.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/core/usecases/usecase.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';

class GetAllTracks implements UseCase<List<Track>, NoParams> {
  final TrackRepository repository;

  GetAllTracks(this.repository);

  @override
  Future<Either<Failure, List<Track>>> call(_) async {
    return await repository.getAllTracks();
  }
}
