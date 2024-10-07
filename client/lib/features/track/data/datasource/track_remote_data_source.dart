import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/features/track/data/models/track_model.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class TrackRemoteDataSource {
  Future<List<MinimalTrack>> getAllTracks() async {
    try {
      final response = await AppApi().dio.get("/track");

      return (response.data as List)
          .map(
            (rawModel) => MinimalTrackModel.fromJson(rawModel).toMinimalTrack(),
          )
          .toList();
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      throw ServerUnknownException();
    } catch (e, st) {
      print(st);

      throw ServerUnknownException();
    }
  }
}

final trackRemoteDataSourceProvider = Provider(
  (ref) => TrackRemoteDataSource(),
);
