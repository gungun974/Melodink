import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:melodink_client/config.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/tracks/data/models/track.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';

class TrackRepositoryImpl implements TrackRepository {
  final http.Client client;

  TrackRepositoryImpl({required this.client});

  @override
  Future<Result<List<Track>>> getAllTracks() async {
    final response = await client.get(Uri.parse('$appUrl/api/track'));

    if (response.statusCode == 200) {
      try {
        final tracks = (json.decode(response.body) as List)
            .map(
              (track) => TrackJson.fromJson(
                track,
              ).toTrack(),
            )
            .toList();

        return Ok(
          tracks,
        );
      } catch (e) {
        return Err(ServerFailure());
      }
    }

    return Err(ServerFailure());
  }
}
