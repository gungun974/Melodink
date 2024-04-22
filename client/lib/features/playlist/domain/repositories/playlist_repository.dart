import 'package:fpdart/fpdart.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';

abstract class PlaylistRepository {
  Future<Either<Failure, List<Playlist>>> getAllAlbums();
}
