import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/like_track_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/open_queue_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_play_pause_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_repeat_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_shuffle_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_skip_to_next_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_skip_to_previous_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/volume_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';

class SidePlayerBar extends ConsumerWidget {
  const SidePlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackStreamProvider).valueOrNull;
    final scoringSystem = ref.watch(currentScoringSystemProvider);

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: IntrinsicHeight(
                child: LargePlayerSeeker(
                  displayDurationsInBottom: true,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PlayerShuffleControl(
                  largeControlButton: false,
                ),
                PlayerSkipToPreviousControl(
                  largeControlButton: true,
                ),
                PlayerPlayPauseControl(
                  largeControlButton: true,
                ),
                PlayerSkipToNextControl(
                  largeControlButton: true,
                ),
                PlayerRepeatControl(
                  largeControlButton: false,
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (scoringSystem != AppSettingScoringSystem.none)
                CurrentTrackScoreControl(),
              if (scoringSystem != AppSettingScoringSystem.none) Spacer(),
              VolumeControl(),
              Spacer(),
              OpenQueueControl(),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
