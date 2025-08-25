import 'dart:math';

import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/tracker/domain/events/history_events.dart';
import 'package:audio_service/audio_service.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';

class PlayerTrackerManager {
  final EventBus eventBus;

  final PlayedTrackRepository playedTrackRepository;

  late Stream<List<PlaybackState>> lastState;

  PlayerTrackerManager({
    required this.eventBus,
    required this.playedTrackRepository,
  });

  void watchState(
    PlaybackState lastState,
    PlaybackState currentState,
    Track? currentTrack,
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
  Track? _lastTrackingTrack;

  bool _resetAntiEndSpam = false;

  void _startTrackTracking(Duration startPosition) {
    _trackedStartAt = DateTime.now();
    _trackedFinishAt = null;

    _trackedBeginAt = startPosition;
    _trackedEndedAt = null;

    _startTrackingTrack = true;
  }

  void _finishTrackTracking(Duration endPosition) {
    if (!_startTrackingTrack) {
      return;
    }

    _startTrackingTrack = false;

    _trackedFinishAt = DateTime.now();

    _trackedEndedAt = endPosition;

    _registerTrackTracking();
  }

  void _registerTrackTracking() {
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
          milliseconds: max(
            (currentTrack.duration * 0.01).inMilliseconds,
            1000,
          ),
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
            trackDuration: currentTrack.duration,
          )
          .then((playedTrack) {
            eventBus.fire(NewPlayedTrackEvent(newPlayedTrack: playedTrack));
          });

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
