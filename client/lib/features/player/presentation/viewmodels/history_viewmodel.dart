import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/events/history_events.dart';

class HistoryViewModel extends ChangeNotifier {
  EventBus eventBus;
  PlayedTrackRepository playedTrackRepository;

  StreamSubscription? _managerNewPlayedTrackStream;

  HistoryViewModel({
    required this.eventBus,
    required this.playedTrackRepository,
  }) {
    _managerNewPlayedTrackStream = eventBus.on<NewPlayedTrackEvent>().listen((
      _,
    ) {
      fetchLastHistoryTracks();
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
