import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/library/data/models/artist_model.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';

class ArtistRemoteDataSource {
  Future<List<Artist>> getAllArtists() async {
    try {
      final response = await AppApi().dio.get("/artist");

      return (response.data as List)
          .map(
            (rawModel) => ArtistModel.fromJson(rawModel).toArtist(),
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

  Future<Artist> getArtistById(int id) async {
    try {
      final response = await AppApi().dio.get("/artist/$id");

      return ArtistModel.fromJson(response.data).toArtist();
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw ArtistNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final artistRemoteDataSourceProvider = Provider(
  (ref) => ArtistRemoteDataSource(),
);
