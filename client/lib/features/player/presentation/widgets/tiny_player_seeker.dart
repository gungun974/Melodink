import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';

class TinyPlayerSeeker extends ConsumerWidget {
  const TinyPlayerSeeker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final audioControllerPositionDataStream = ref.watch(
      audioControllerPositionDataStreamProvider,
    );

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          value: position.inMilliseconds / duration.inMilliseconds,
        ),
      ),
    );
  }
}
