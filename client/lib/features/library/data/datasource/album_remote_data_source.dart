import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/library/data/models/album_model.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';

class AlbumRemoteDataSource {
  Future<List<Album>> getAllAlbums() async {
    try {
      final response = await AppApi().dio.get("/album");

      return (response.data as List)
          .map(
            (rawModel) => AlbumModel.fromJson(rawModel).toAlbum(),
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

  Future<Album> getAlbumById(String id) async {
    try {
      final response = await AppApi().dio.get("/album/$id");

      return AlbumModel.fromJson(response.data).toAlbum();
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw AlbumNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final albumRemoteDataSourceProvider = Provider(
  (ref) => AlbumRemoteDataSource(),
);
