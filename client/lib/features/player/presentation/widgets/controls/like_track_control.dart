import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/hooks/use_behavior_subject_stream.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_score.dart';

class CurrentTrackScoreControl extends HookConsumerWidget {
  final bool largeControlButton;

  const CurrentTrackScoreControl({super.key, this.largeControlButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.read(audioControllerProvider);

    final currentTrack = useBehaviorSubjectStream(
      audioController.currentTrack,
    ).data;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return TrackScore(
      track: currentTrack,
      largeControlButton: largeControlButton,
    );
  }
}
