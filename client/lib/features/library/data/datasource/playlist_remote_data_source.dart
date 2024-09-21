import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/library/data/models/playlist_model.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';

class PlaylistRemoteDataSource {
  Future<List<Playlist>> getAllPlaylists() async {
    try {
      final response = await AppApi().dio.get("/playlist");

      return (response.data as List)
          .map(
            (rawModel) => PlaylistModel.fromJson(rawModel).toPlaylist(),
          )
          .toList();
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      throw ServerUnknownException();
    } catch (e) {
      throw ServerUnknownException();
    }
  }

  Future<Playlist> getPlaylistById(int id) async {
    try {
      final response = await AppApi().dio.get("/playlist/$id");

      return PlaylistModel.fromJson(response.data).toPlaylist();
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw PlaylistNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final playlistRemoteDataSourceProvider = Provider(
  (ref) => PlaylistRemoteDataSource(),
);
