import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'played_track_provider.g.dart';

@riverpod
Future<List<MinimalTrack>> lastHistoryTracks(Ref ref) async {
  final manager = ref.watch(playerTrackerManagerProvider);

  final subscription = manager.newPlayedTrack.listen((playedTrack) {
    ref.invalidate(lastHistoryTracksProvider);
  });

  ref.onDispose(() {
    subscription.cancel();
  });

  final playedTrackRepository = ref.watch(playedTrackRepositoryProvider);

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
