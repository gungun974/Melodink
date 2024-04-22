import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:melodink_client/config.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/playlist/data/models/playlist.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:melodink_client/features/playlist/domain/repositories/playlist_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final http.Client client;

  PlaylistRepositoryImpl({required this.client});

  @override
  Future<Either<Failure, List<Playlist>>> getAllAlbums() async {
    final response = await client.get(Uri.parse('$appUrl/api/playlist/albums'));

    if (response.statusCode == 200) {
      try {
        final albums = (json.decode(response.body) as List)
            .map(
              (playlist) => PlaylistJson.fromJson(
                playlist,
              ).toPlaylist(),
            )
            .toList();

        return Either.of(
          albums,
        );
      } catch (e) {
        return Either.left(ServerFailure());
      }
    }

    return Either.left(ServerFailure());
  }
}
