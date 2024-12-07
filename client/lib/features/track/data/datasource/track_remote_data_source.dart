import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/track/data/models/track_model.dart';
import 'package:melodink_client/features/track/data/models/minimal_track_model.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
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
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Track> getTrackById(int id) async {
    try {
      final response = await AppApi().dio.get("/track/$id");

      return TrackModel.fromJson(response.data).toTrack();
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Track> saveTrack(Track track) async {
    try {
      final response = await AppApi().dio.put(
        "/track/${track.id}",
        data: {
          "id": track.id,
          "title": track.title,
          "album": track.metadata.album,
          "track_number": track.metadata.trackNumber,
          "total_tracks": track.metadata.totalTracks,
          "disc_number": track.metadata.discNumber,
          "total_discs": track.metadata.totalDiscs,
          "date": track.metadata.date,
          "year": track.metadata.year,
          "genres": track.metadata.genres,
          "lyrics": track.metadata.lyrics,
          "comment": track.metadata.composer,
          "artists":
              track.metadata.artists.map((artist) => artist.name).toList(),
          "album_artists":
              track.metadata.albumArtists.map((artist) => artist.name).toList(),
          "composer": track.metadata.composer,
          "acoust_id": track.metadata.acoustId,
          "music_brainz_release_id": track.metadata.musicBrainzReleaseId,
          "music_brainz_track_id": track.metadata.musicBrainzTrackId,
          "music_brainz_recording_id": track.metadata.musicBrainzRecordingId,
          "date_added": track.dateAdded.toUtc().toIso8601String(),
        },
      );

      return TrackModel.fromJson(response.data).toTrack();
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final trackRemoteDataSourceProvider = Provider(
  (ref) => TrackRemoteDataSource(),
);
