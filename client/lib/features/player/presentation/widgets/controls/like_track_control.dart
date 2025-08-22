import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/hooks/use_behavior_subject_stream.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_score.dart';
import 'package:provider/provider.dart';

class CurrentTrackScoreControl extends HookWidget {
  final bool largeControlButton;

  const CurrentTrackScoreControl({super.key, this.largeControlButton = false});

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

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
