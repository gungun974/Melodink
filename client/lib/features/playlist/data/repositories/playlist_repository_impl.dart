import 'dart:convert';

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
  Future<Result<List<Playlist>>> getAllAlbums() async {
    final response = await client.get(
      Uri.parse('$appUrl/api/playlist/album'),
    );

    if (response.statusCode == 200) {
      try {
        final albums = (json.decode(response.body) as List)
            .map(
              (playlist) => PlaylistJson.fromJson(
                playlist,
              ).toPlaylist(),
            )
            .toList();

        return Ok(
          albums,
        );
      } catch (e) {
        return Err(ServerFailure());
      }
    }

    return Err(ServerFailure());
  }

  @override
  Future<Result<Playlist>> getAlbumById(String id) async {
    final response = await client.get(
      Uri.parse('$appUrl/api/playlist/album/$id'),
    );

    switch (response.statusCode) {
      case 200:
        try {
          final album = json.decode(response.body);

          return Ok(PlaylistJson.fromJson(
            album,
          ).toPlaylist());
        } catch (e) {
          return Err(ServerFailure());
        }
      case 404:
        return Err(PlaylistNotFoundFailure());
      default:
        return Err(ServerFailure());
    }
  }
}
