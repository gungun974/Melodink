import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';

class HistoryViewModel extends ChangeNotifier {
  PlayerTrackerManager manager;
  PlayedTrackRepository playedTrackRepository;

  StreamSubscription? _managerNewPlayedTrackStream;

  HistoryViewModel({
    required this.manager,
    required this.playedTrackRepository,
  }) {
    _managerNewPlayedTrackStream = manager.newPlayedTrack.listen((playedTrack) {
      // ref.invalidate(lastHistoryTracksProvider);
    });
  }

  @override
  void dispose() {
    _managerNewPlayedTrackStream?.cancel();
    super.dispose();
  }

  List<Track> previousTracks = [];

  Future<void> fetchLastHistoryTracks() async {
    previousTracks = await playedTrackRepository.getLastPlayedTracks();

    notifyListeners();
  }
}
