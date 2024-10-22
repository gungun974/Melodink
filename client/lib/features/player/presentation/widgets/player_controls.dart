import 'package:flutter/material.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_play_pause_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_repeat_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_skip_to_next_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_skip_to_previous_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_shuffle_control.dart';

class PlayerControls extends StatelessWidget {
  final bool largeControlsButton;

  const PlayerControls({
    super.key,
    this.largeControlsButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: largeControlsButton
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PlayerShuffleControl(
          largeControlButton: largeControlsButton,
        ),
        PlayerSkipToPreviousControl(
          largeControlButton: largeControlsButton,
        ),
        PlayerPlayPauseControl(
          largeControlButton: largeControlsButton,
        ),
        PlayerSkipToNextControl(
          largeControlButton: largeControlsButton,
        ),
        PlayerRepeatControl(
          largeControlButton: largeControlsButton,
        ),
      ],
    );
  }
}
