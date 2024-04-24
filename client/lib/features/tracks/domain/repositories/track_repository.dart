import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';

abstract class TrackRepository {
  Future<Result<List<Track>>> getAllTracks();
}
