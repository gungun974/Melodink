import 'dart:math';

import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/providers/played_track_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'player_tracker_manager_provider.g.dart';

@Riverpod(keepAlive: true)
class PlayerTrackerManagerNotifier extends _$PlayerTrackerManagerNotifier {
  late AudioController _audioController;
  late PlayedTrackRepository _playedTrackRepository;

  @override
  void build() {
    _audioController = ref.read(audioControllerProvider);
    _playedTrackRepository = ref.read(playedTrackRepositoryProvider);

    _audioController.playbackState
        .distinct((previous, current) {
          return (previous.position - current.position).inMilliseconds.abs() <=
                  1 &&
              previous.playing == current.playing;
        })
        .pairwise()
        .listen(
          (pair) {
            if (pair.lastOrNull == null) {
              return;
            }

            final currentState = pair.last;
            final lastState = pair.first;

            final currentPosition = currentState.position;
            final lastPosition = lastState.position;

            final hasPositionLargelyChanged =
                (currentPosition - lastPosition).inMilliseconds.abs() >= 300;

            final hasChangedQueueIndex =
                currentState.queueIndex != lastState.queueIndex;

            if (hasPositionLargelyChanged) {
              _resetAntiEndSpam = false;
            }

            if (_startTrackingTrack &&
                (hasPositionLargelyChanged || hasChangedQueueIndex)) {
              _finishTrackTracking(lastPosition);
            }

            if (_startTrackingTrack && !currentState.playing) {
              _finishTrackTracking(currentPosition);
            }

            if (!_startTrackingTrack && currentState.playing) {
              _startTrackTracking();
            }

            _lastTrackingTrack = _audioController.currentTrack.valueOrNull;
          },
        );
  }

  DateTime? _trackedStartAt;
  DateTime? _trackedFinishAt;

  Duration? _trackedBeginAt;
  Duration? _trackedEndedAt;

  bool _startTrackingTrack = false;
  MinimalTrack? _lastTrackingTrack;

  bool _resetAntiEndSpam = false;

  _startTrackTracking() {
    final state = _audioController.playbackState.value;

    _trackedStartAt = DateTime.now();
    _trackedFinishAt = null;

    _trackedBeginAt = state.position;
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
      _playedTrackRepository.addPlayedTrack(
        trackId: currentTrack.id,
        startAt: startAt,
        finishAt: finishAt,
        beginAt: beginAt,
        endedAt: endedAt,
        shuffle: _audioController.isShuffled,
        trackEnded: trackEnded,
      );

      ref.invalidate(lastHistoryTracksProvider);

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
