import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';
import 'package:melodink_client/generated/pb/google/protobuf/empty.pb.dart';
import 'package:melodink_client/generated/pb/track.pbgrpc.dart' as pb;

class TrackRepositoryImpl implements TrackRepository {
  final ClientChannel grpcClient;

  final pb.TrackServiceClient trackServiceClient;

  TrackRepositoryImpl({required this.grpcClient})
      : trackServiceClient = pb.TrackServiceClient(grpcClient);

  @override
  Future<Either<Failure, Stream<Track>>> getAllTracks() async {
    try {
      final stream = trackServiceClient.listAllTracks(Empty());

      return Either.of(stream.map((track) => Track(
            id: track.id,
            title: track.title,
            album: track.album,
            duration: Duration(milliseconds: track.duration),
            tagsFormat: track.tagsFormat,
            fileType: track.fileType,
            path: track.path,
            fileSignature: track.fileSignature,
            metadata: TrackMetadata(
                trackNumber: track.metadata.trackNumber,
                totalTracks: track.metadata.totalTracks,
                discNumber: track.metadata.discNumber,
                totalDiscs: track.metadata.totalDiscs,
                date: track.metadata.date,
                year: track.metadata.year,
                genre: track.metadata.genre,
                lyrics: track.metadata.lyrics,
                comment: track.metadata.comment,
                acoustID: track.metadata.acoustId,
                acoustIDFingerprint: track.metadata.acoustIdFingerprint,
                artist: track.metadata.artist,
                albumArtist: track.metadata.albumArtist,
                composer: track.metadata.composer,
                copyright: track.metadata.copyright),
          )));
    } catch (e) {
      print('Caught error: $e');
    }

    return Either.left(ServerFailure());
  }
}
