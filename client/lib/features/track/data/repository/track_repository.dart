import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/track/data/datasource/track_local_data_source.dart';
import 'package:melodink_client/features/track/data/datasource/track_remote_data_source.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';

class TrackNotFoundException implements Exception {}

class TrackRepository {
  final TrackRemoteDataSource trackRemoteDataSource;
  final TrackLocalDataSource trackLocalDataSource;

  final PlayedTrackRepository playedTrackRepository;

  final NetworkInfo networkInfo;

  TrackRepository({
    required this.trackRemoteDataSource,
    required this.trackLocalDataSource,
    required this.playedTrackRepository,
    required this.networkInfo,
  });

  Future<List<MinimalTrack>> getAllTracks() async {
    List<MinimalTrack> tracks;

    if (networkInfo.isServerRecheable()) {
      try {
        tracks = await trackRemoteDataSource.getAllTracks();
      } catch (_) {
        tracks = await trackLocalDataSource.getAllTracks();
      }
    } else {
      tracks = await trackLocalDataSource.getAllTracks();
    }

    await playedTrackRepository.loadTrackHistoryIntoMinimalTracks(tracks);

    return tracks;
  }

  Future<Track> getTrackById(int id) async {
    final track = await trackRemoteDataSource.getTrackById(id);
    final info = await playedTrackRepository.getTrackHistoryInfo(id);

    return track.copyWith(
      historyInfo: () => info,
    );
  }

  Future<Track> saveTrack(Track track) async {
    final updatedTrack = await trackRemoteDataSource.saveTrack(track);
    final info = await playedTrackRepository.getTrackHistoryInfo(
      updatedTrack.id,
    );

    return updatedTrack.copyWith(
      historyInfo: () => info,
    );
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
    playedTrackRepository: ref.watch(
      playedTrackRepositoryProvider,
    ),
    networkInfo: ref.watch(
      networkInfoProvider,
    ),
  ),
);
