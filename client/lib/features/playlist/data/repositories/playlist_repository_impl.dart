import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:melodink_client/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:melodink_client/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:melodink_client/generated/pb/google/protobuf/empty.pb.dart';
import 'package:melodink_client/generated/pb/playlist.pbgrpc.dart' as pb;

class PlaylistRepositoryImpl implements PlaylistRepository {
  final ClientChannelBase grpcClient;

  final pb.PlaylistServiceClient playlistServiceClient;

  PlaylistRepositoryImpl({required this.grpcClient})
      : playlistServiceClient = pb.PlaylistServiceClient(grpcClient);

  @override
  Future<Either<Failure, List<Playlist>>> getAllAlbums() async {
    try {
      final playlistList = await playlistServiceClient.listAllAlbums(Empty());

      return Either.of(
        playlistList.playlists.map(
          (playlist) {
            var playlistType = PlaylistType.custom;

            switch (playlist.type) {
              case pb.PlaylistType.CUSTOM:
                playlistType = PlaylistType.custom;
                break;
              case pb.PlaylistType.ALBUM:
                playlistType = PlaylistType.album;
                break;
              case pb.PlaylistType.ARTIST:
                playlistType = PlaylistType.artist;
                break;
            }

            return Playlist(
              id: playlist.id,
              name: playlist.name,
              description: playlist.description,
              albumArtist: playlist.albumArtist,
              type: playlistType,
              tracks: playlist.tracks
                  .map(TrackRepositoryImpl.decodeGRPCTrack)
                  .toList(),
            );
          },
        ).toList(),
      );
    } catch (e) {
      print('Caught error: $e');
    }

    return Either.left(ServerFailure());
  }
}
