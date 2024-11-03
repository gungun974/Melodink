import 'package:melodink_client/features/tracker/data/repository/sync_shared_played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/manager/shared_player_tracker_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_played_track_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPlayedTrackerManager sharedPlayedTrackerManager(
  SharedPlayedTrackerManagerRef ref,
) {
  final syncSharedPlayedTrackRepository =
      ref.watch(syncSharedPlayedTrackRepositoryProvider);

  final manager = SharedPlayedTrackerManager(
    syncSharedPlayedTrackRepository: syncSharedPlayedTrackRepository,
  );

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
}
