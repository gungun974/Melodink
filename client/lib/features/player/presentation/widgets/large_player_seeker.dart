import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:rxdart/rxdart.dart';

class LargePlayerSeeker extends StatefulWidget {
  final bool displayDurationsInBottom;

  const LargePlayerSeeker({
    super.key,
    this.displayDurationsInBottom = false,
  });

  @override
  State<LargePlayerSeeker> createState() => _LargePlayerSeekerState();
}

class _LargePlayerSeekerState extends State<LargePlayerSeeker> {
  final AudioController audioController = sl();

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, PlaybackState, MediaItem?, PositionData>(
        AudioService.position,
        audioController.playbackState,
        audioController.mediaItem,
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
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
        stream: positionDataStream,
        builder: (context, snapshot) {
          final positionData = snapshot.data;

          Duration trackDuration = Duration.zero;

          if (audioController.currentTrack.value != null) {
            trackDuration = audioController.currentTrack.value!.duration;
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
              audioController.playbackState.value.playing == false) {
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
            onSeek: audioController.seek,
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
              Future.delayed(const Duration(milliseconds: 30), () {
                setState(() {
                  newSeekFuture = null;
                });
              });
            },
          );

          if (widget.displayDurationsInBottom) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: progressBar),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      durationToTime(position),
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 12 * 0.03,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      durationToTime(duration),
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 12 * 0.03,
                        fontWeight: FontWeight.w300,
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
                durationToTime(position),
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 12 * 0.03,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: progressBar,
              ),
              const SizedBox(width: 12.0),
              Text(
                durationToTime(duration),
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 12 * 0.03,
                  fontWeight: FontWeight.w300,
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