import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class TrackLocalDataSource {
  Future<List<MinimalTrack>> getAllTracks() async {
    return [];
  }
}

final trackLocalDataSourceProvider = Provider(
  (ref) => TrackLocalDataSource(),
);
