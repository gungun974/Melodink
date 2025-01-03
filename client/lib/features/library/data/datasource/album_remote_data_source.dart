import 'dart:io';

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

  Future<List<Album>> getAllAlbumsWithTracks() async {
    try {
      final response = await AppApi().dio.get("/album/full");

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

  Future<Map<String, String>> getAllAlbumsCoverSignatures() async {
    try {
      final response = await AppApi().dio.get("/album/covers/signatures");

      return Map<String, String>.from(response.data);
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

  Future<Album> changeAlbumCover(String id, File file) async {
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      final response = await AppApi().dio.put(
            "/album/$id/cover",
            data: formData,
          );

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

  Future<Album> removeAlbumCover(String id) async {
    try {
      final response = await AppApi().dio.delete(
            "/album/$id/cover",
          );

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
