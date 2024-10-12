import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'played_track_provider.g.dart';

@riverpod
Future<List<MinimalTrack>> lastHistoryTracks(LastHistoryTracksRef ref) async {
  final playedTrackRepository = ref.read(playedTrackRepositoryProvider);

  final allTracks = await ref.watch(allTracksProvider.future);

  final previousPlayedTracks =
      await playedTrackRepository.getLastPlayedTracks();

  final List<MinimalTrack> previousTracks = [];

  for (final previousPlayedTrack in previousPlayedTracks.reversed) {
    final track = allTracks
        .where(
          (track) => track.id == previousPlayedTrack.trackId,
        )
        .firstOrNull;

    if (track == null) {
      continue;
    }

    previousTracks.add(track);
  }

  return previousTracks;
}

@riverpod
Future<DateTime?> lastPlayedTrackDate(
    LastPlayedTrackDateRef ref, int trackId) async {
  final playedTrackRepository = ref.read(playedTrackRepositoryProvider);

  final lastPlayed =
      await playedTrackRepository.getLastFinishedPlayedTrackByTrackId(trackId);

  if (lastPlayed == null) {
    return null;
  }

  return lastPlayed.finishAt;
}

@riverpod
Future<int> trackPlayedCount(TrackPlayedCountRef ref, int trackId) async {
  final playedTrackRepository = ref.read(playedTrackRepositoryProvider);

  return await playedTrackRepository.getTrackPlayedCountByTrackId(trackId);
}
