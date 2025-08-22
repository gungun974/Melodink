import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:provider/provider.dart';

class PlayerPlayPauseControl extends StatelessWidget {
  final bool largeControlButton;

  const PlayerPlayPauseControl({super.key, this.largeControlButton = false});

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    return StreamBuilder<PlaybackState>(
      stream: audioController.playbackState,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return AppIconButton(
          padding: const EdgeInsets.all(8),
          icon: isPlaying
              ? const AdwaitaIcon(AdwaitaIcons.media_playback_pause)
              : const AdwaitaIcon(AdwaitaIcons.media_playback_start),
          iconSize: largeControlButton ? 52.0 : 36.0,
          onPressed: () async {
            if (isPlaying) {
              await audioController.pause();
              return;
            }
            await audioController.play();
          },
        );
      },
    );
  }
}
