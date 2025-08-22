import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:provider/provider.dart';

class PlayerRepeatControl extends StatelessWidget {
  final bool largeControlButton;

  const PlayerRepeatControl({super.key, this.largeControlButton = false});

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    return StreamBuilder<PlaybackState>(
      stream: audioController.playbackState,
      builder: (context, snapshot) {
        final repeatMode =
            snapshot.data?.repeatMode ?? AudioServiceRepeatMode.none;
        return AppIconButton(
          padding: const EdgeInsets.all(8),
          icon: repeatMode == AudioServiceRepeatMode.one
              ? const AdwaitaIcon(AdwaitaIcons.media_playlist_repeat_song)
              : const AdwaitaIcon(AdwaitaIcons.media_playlist_repeat),
          iconSize: largeControlButton ? 24.0 : 20.0,
          color: repeatMode != AudioServiceRepeatMode.none
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          onPressed: () async {
            switch (repeatMode) {
              case AudioServiceRepeatMode.none:
                await audioController.setRepeatMode(AudioServiceRepeatMode.all);
                break;
              case AudioServiceRepeatMode.all:
                await audioController.setRepeatMode(AudioServiceRepeatMode.one);
                break;
              case AudioServiceRepeatMode.one:
                await audioController.setRepeatMode(
                  AudioServiceRepeatMode.none,
                );
                break;
              default:
            }
          },
        );
      },
    );
  }
}
