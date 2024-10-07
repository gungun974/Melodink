import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/track/data/datasource/track_local_data_source.dart';
import 'package:melodink_client/features/track/data/datasource/track_remote_data_source.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class TrackNotFoundException implements Exception {}

class TrackRepository {
  final TrackRemoteDataSource trackRemoteDataSource;
  final TrackLocalDataSource trackLocalDataSource;

  final NetworkInfo networkInfo;

  TrackRepository({
    required this.trackRemoteDataSource,
    required this.trackLocalDataSource,
    required this.networkInfo,
  });

  Future<List<MinimalTrack>> getAllTracks() async {
    if (networkInfo.isServerRecheable()) {
      try {
        return await trackRemoteDataSource.getAllTracks();
      } catch (_) {
        return await trackLocalDataSource.getAllTracks();
      }
    }

    return await trackLocalDataSource.getAllTracks();
  }
}

final trackRepositoryProvider = Provider(
  (ref) => TrackRepository(
    trackRemoteDataSource: ref.watch(
      trackRemoteDataSourceProvider,
    ),
    trackLocalDataSource: ref.watch(
      trackLocalDataSourceProvider,
    ),
    networkInfo: ref.watch(
      networkInfoProvider,
    ),
  ),
);
