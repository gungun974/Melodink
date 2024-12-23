import 'dart:async';
import 'dart:io';

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

  Future<List<MinimalTrack>> getAllPendingImportTracks() async {
    return await trackRemoteDataSource.getAllPendingImportTracks();
  }

  Future<Track> getTrackById(int id) async {
    final track = await trackRemoteDataSource.getTrackById(id);
    final info = await playedTrackRepository.getTrackHistoryInfo(id);

    return track.copyWith(
      historyInfo: () => info,
    );
  }

  Future<String> getTrackLyricsById(int id) async {
    return await trackRemoteDataSource.getTrackLyricsById(id);
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

  Future<Track> uploadAudio(
    File file, {
    StreamController<double>? progress,
  }) async {
    return await trackRemoteDataSource.uploadAudio(file, progress: progress);
  }

  Future<Track> changeTrackAudio(int id, File file) async {
    return await trackRemoteDataSource.changeTrackAudio(id, file);
  }

  Future<Track> changeTrackCover(int id, File file) async {
    return await trackRemoteDataSource.changeTrackCover(id, file);
  }

  Future<Track> deleteTrackById(int id) async {
    return await trackRemoteDataSource.deleteTrackById(id);
  }

  importPendingTracks() async {
    await trackRemoteDataSource.importPendingTracks();
  }

  Future<Track> scanAudio(int id) async {
    return await trackRemoteDataSource.scanAudio(id);
  }

  Future<Track> advancedAudioScan(int id) async {
    return await trackRemoteDataSource.advancedAudioScan(id);
  }

  Future<Track> setTrackScore(int id, double score) async {
    return await trackRemoteDataSource.setTrackScore(id, score);
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
