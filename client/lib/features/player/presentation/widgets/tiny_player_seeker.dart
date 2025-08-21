import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/hooks/use_behavior_subject_stream.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';

class TinyPlayerSeeker extends HookConsumerWidget {
  const TinyPlayerSeeker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.read(audioControllerProvider);

    final audioControllerPositionDataStream = useBehaviorSubjectStream(
      audioController.getPositionData(),
    );

    final positionData = audioControllerPositionDataStream.data;

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

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            value: position.inMilliseconds / duration.inMilliseconds,
          ),
        ),
      ),
    );
  }
}
