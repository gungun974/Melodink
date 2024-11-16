import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';

class LargePlayerSeeker extends HookConsumerWidget {
  final bool displayDurationsInBottom;
  final bool large;

  const LargePlayerSeeker({
    super.key,
    this.displayDurationsInBottom = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final audioControllerPositionDataStream = ref.watch(
      audioControllerPositionDataStreamProvider,
    );

    final newSeekFuture = useState<Duration?>(null);

    final positionData = audioControllerPositionDataStream.valueOrNull;

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

    if (newSeekFuture.value != null) {
      position = newSeekFuture.value ?? position;
    }

    final progressBar = AbsorbPointer(
      absorbing: duration.inMilliseconds < 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        clipBehavior: large ? Clip.antiAlias : Clip.none,
        child: ProgressBar(
          barHeight: large ? 16.0 : 5.0,
          thumbRadius: large ? 0 : 7.0,
          thumbGlowRadius: large ? 0 : 30.0,
          thumbColor: Colors.white,
          baseBarColor: Colors.grey[800],
          progressBarColor: Colors.white,
          barCapShape: BarCapShape.square,
          progress: position,
          total: duration,
          timeLabelLocation: TimeLabelLocation.none,
          onSeek: audioController.seek,
          onDragStart: (thumbValue) {
            newSeekFuture.value = thumbValue.timeStamp;
          },
          onDragUpdate: (thumbValue) {
            newSeekFuture.value = thumbValue.timeStamp;
          },
          onDragEnd: () {
            Future.delayed(const Duration(milliseconds: 30), () {
              newSeekFuture.value = null;
            });
          },
        ),
      ),
    );

    if (displayDurationsInBottom) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: progressBar),
            ],
          ),
          SizedBox(height: large ? 8.0 : 4.0),
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
