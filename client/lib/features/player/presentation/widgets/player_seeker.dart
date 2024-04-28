import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:rxdart/rxdart.dart';

class PlayerSeeker extends StatefulWidget {
  final bool autoMaxWidth;
  final bool showBottomDurations;

  const PlayerSeeker({
    super.key,
    this.autoMaxWidth = true,
    this.showBottomDurations = false,
  });

  @override
  State<PlayerSeeker> createState() => _PlayerSeekerState();
}

class _PlayerSeekerState extends State<PlayerSeeker> {
  final _audioHandler = sl<AudioHandler>();

  late final audioServiceDurationStreamController =
      StreamController<Duration>();
  late final audioServiceDurationStream =
      audioServiceDurationStreamController.stream.asBroadcastStream();

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, PlaybackState, MediaItem?, PositionData>(
        audioServiceDurationStream,
        _audioHandler.playbackState,
        _audioHandler.mediaItem,
        (position, playerState, duration) {
          return PositionData(
            position: position,
            bufferedPosition: playerState.bufferedPosition,
            duration: duration?.duration ?? Duration.zero,
          );
        },
      );

  Duration? newSeekFuture;

  @override
  void initState() {
    super.initState();

    if (!_audioHandler.playbackState.value.playing) {
      audioServiceDurationStreamController
          .add(_audioHandler.playbackState.value.position);
    }

    AudioService.position.listen(
      (duration) {
        audioServiceDurationStreamController.add(
          _audioHandler.playbackState.value.position,
        );
      },
      onError: (error) {
        audioServiceDurationStreamController.addError(error);
      },
      onDone: () {
        audioServiceDurationStreamController.close();
      },
    );

    _audioHandler.playbackState.listen(
      (_) {
        audioServiceDurationStreamController.add(
          _audioHandler.playbackState.value.position,
        );
      },
      onError: (error) {
        audioServiceDurationStreamController.addError(error);
      },
      onDone: () {
        audioServiceDurationStreamController.close();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
        stream: positionDataStream,
        builder: (context, snapshot) {
          final positionData = snapshot.data;

          final state = BlocProvider.of<PlayerCubit>(context).state;

          Duration trackDuration = Duration.zero;

          if (state is PlayerPlaying) {
            trackDuration = state.currentTrack.duration;
          }

          Duration position = positionData?.position ?? Duration.zero;
          Duration duration = positionData?.duration ?? trackDuration;

          if (position.inHours >= 8760) {
            position = Duration.zero;
          }

          if (duration.inHours >= 8760 || duration.inMilliseconds == 0) {
            duration = trackDuration;
          }

          if ((position - duration).inMilliseconds.abs() < 800 &&
              _audioHandler.playbackState.value.playing == false) {
            position = duration;
          }

          if (newSeekFuture != null) {
            position = newSeekFuture ?? position;
          }

          final progressBar = ProgressBar(
            barHeight: 5.0,
            thumbRadius: 7.0,
            thumbColor: Colors.white,
            baseBarColor: Colors.grey[800],
            progressBarColor: Colors.white,
            progress: position,
            total: duration,
            timeLabelLocation: TimeLabelLocation.none,
            onSeek: BlocProvider.of<PlayerCubit>(context).seek,
            onDragStart: (thumbValue) {
              setState(() {
                newSeekFuture = thumbValue.timeStamp;
              });
            },
            onDragUpdate: (thumbValue) {
              setState(() {
                newSeekFuture = thumbValue.timeStamp;
              });
            },
            onDragEnd: () {
              setState(() {
                newSeekFuture = null;
              });
            },
          );

          final progressBarContainer = widget.autoMaxWidth
              ? SizedBox(
                  width: MediaQuery.of(context).size.width * 0.325,
                  child: progressBar,
                )
              : Expanded(
                  child: progressBar,
                );

          if (widget.showBottomDurations) {
            return Column(
              children: [
                Row(
                  children: [
                    progressBarContainer,
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      key: const Key("positionText"),
                      durationToTime(position),
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      key: const Key("durationText"),
                      durationToTime(duration),
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                key: const Key("positionText"),
                durationToTime(position),
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8.0),
              progressBarContainer,
              const SizedBox(width: 8.0),
              Text(
                key: const Key("durationText"),
                durationToTime(duration),
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          );
        });
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}
