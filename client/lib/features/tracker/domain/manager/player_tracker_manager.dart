import 'dart:math';

import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/tracker/domain/providers/played_track_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/entities/played_track.dart';

class PlayerTrackerManager {
  final PlayedTrackRepository playedTrackRepository;

  late Stream<List<PlaybackState>> lastState;

  PlayerTrackerManager({
    required this.playedTrackRepository,
  });

  final PublishSubject<PlayedTrack> newPlayedTrack =
      PublishSubject<PlayedTrack>();

  watchState(
    PlaybackState lastState,
    PlaybackState currentState,
    MinimalTrack? currentTrack,
  ) {
    final currentPosition = currentState.position;
    final lastPosition = lastState.position;

    _isShuffled = currentState.shuffleMode == AudioServiceShuffleMode.all;

    final hasPositionLargelyChanged =
        (currentPosition - lastPosition).inMilliseconds.abs() >= 300;

    final hasChangedQueueIndex =
        currentState.queueIndex != lastState.queueIndex;

    if (_startTrackingTrack &&
        (hasPositionLargelyChanged || hasChangedQueueIndex)) {
      _finishTrackTracking(lastPosition);
    }

    if (_startTrackingTrack && !currentState.playing) {
      _finishTrackTracking(currentPosition);
    }

    if (hasPositionLargelyChanged) {
      _resetAntiEndSpam = false;
    }

    if (!_startTrackingTrack && currentState.playing) {
      _startTrackTracking(currentState.position);
    }

    _lastTrackingTrack = currentTrack;
  }

  bool _isShuffled = false;

  DateTime? _trackedStartAt;
  DateTime? _trackedFinishAt;

  Duration? _trackedBeginAt;
  Duration? _trackedEndedAt;

  bool _startTrackingTrack = false;
  MinimalTrack? _lastTrackingTrack;

  bool _resetAntiEndSpam = false;

  _startTrackTracking(Duration startPosition) {
    _trackedStartAt = DateTime.now();
    _trackedFinishAt = null;

    _trackedBeginAt = startPosition;
    _trackedEndedAt = null;

    _startTrackingTrack = true;
  }

  _finishTrackTracking(Duration endPosition) {
    if (!_startTrackingTrack) {
      return;
    }

    _startTrackingTrack = false;

    _trackedFinishAt = DateTime.now();

    _trackedEndedAt = endPosition;

    _registerTrackTracking();
  }

  _registerTrackTracking() {
    final currentTrack = _lastTrackingTrack;
    if (currentTrack == null) {
      return;
    }

    final startAt = _trackedStartAt;
    final finishAt = _trackedFinishAt;
    Duration? beginAt = _trackedBeginAt;
    final endedAt = _trackedEndedAt;

    if (startAt == null) {
      return;
    }
    if (finishAt == null) {
      return;
    }
    if (beginAt == null) {
      return;
    }
    if (endedAt == null) {
      return;
    }

    if (beginAt.inMilliseconds < 0) {
      beginAt = const Duration();
    }

    bool trackEnded = false;

    if (currentTrack.duration - endedAt >
        Duration(
          milliseconds:
              max((currentTrack.duration * 0.01).inMilliseconds, 1000),
        )) {
    } else {
      trackEnded = true;
    }

    if (trackEnded && _resetAntiEndSpam) {
      _trackedStartAt = null;
      _trackedFinishAt = null;
      _trackedBeginAt = null;
      _trackedEndedAt = null;
      return;
    }

    if ((endedAt - beginAt).inMilliseconds.abs() > 5) {
      playedTrackRepository
          .addPlayedTrack(
            trackId: currentTrack.id,
            startAt: startAt,
            finishAt: finishAt,
            beginAt: beginAt,
            endedAt: endedAt,
            shuffle: _isShuffled,
            trackEnded: trackEnded,
          )
          .then(newPlayedTrack.add);

      if (trackEnded) {
        _resetAntiEndSpam = true;
      }
    }

    _trackedStartAt = null;
    _trackedFinishAt = null;
    _trackedBeginAt = null;
    _trackedEndedAt = null;
  }
}

final playerTrackerManagerProvider = Provider(
  (ref) {
    final manager = PlayerTrackerManager(
      playedTrackRepository: ref.watch(
        playedTrackRepositoryProvider,
      ),
    );

    final subscription = manager.newPlayedTrack.listen((playedTrack) {
      ref.invalidate(lastHistoryTracksProvider);
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    return manager;
  },
);
