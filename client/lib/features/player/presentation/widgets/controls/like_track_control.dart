import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_score.dart';

class CurrentTrackScoreControl extends ConsumerWidget {
  final bool largeControlButton;

  const CurrentTrackScoreControl({
    super.key,
    this.largeControlButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackStreamProvider).valueOrNull;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return TrackScore(
      track: currentTrack,
      largeControlButton: largeControlButton,
    );
  }
}
