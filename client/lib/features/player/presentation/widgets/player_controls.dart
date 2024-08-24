import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/injection_container.dart';

class PlayerControls extends StatefulWidget {
  final bool largeControlsButton;

  const PlayerControls({
    super.key,
    this.largeControlsButton = false,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  final AudioController audioController = sl();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.largeControlsButton
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StreamBuilder(
            stream: audioController.playbackState,
            builder: (context, snapshot) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const AdwaitaIcon(
                  AdwaitaIcons.media_playlist_shuffle,
                ),
                color: snapshot.data?.shuffleMode == AudioServiceShuffleMode.all
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                iconSize: widget.largeControlsButton ? 24.0 : 20.0,
                onPressed: () async {
                  await audioController.toogleShufle();
                },
              );
            }),
        const SizedBox(width: 16),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const AdwaitaIcon(AdwaitaIcons.media_skip_backward),
          iconSize: widget.largeControlsButton ? 28.0 : 20.0,
          onPressed: () async {
            await audioController.skipToPrevious();
          },
        ),
        const SizedBox(width: 16),
        StreamBuilder<PlaybackState>(
            stream: audioController.playbackState,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data?.playing ?? false;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: isPlaying
                    ? const AdwaitaIcon(AdwaitaIcons.media_playback_pause)
                    : const AdwaitaIcon(AdwaitaIcons.media_playback_start),
                iconSize: widget.largeControlsButton ? 52.0 : 36.0,
                onPressed: () async {
                  if (isPlaying) {
                    await audioController.pause();
                    return;
                  }
                  await audioController.play();
                },
              );
            }),
        const SizedBox(width: 16),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const AdwaitaIcon(AdwaitaIcons.media_skip_forward),
          iconSize: widget.largeControlsButton ? 28.0 : 20.0,
          onPressed: () async {
            await audioController.skipToNext();
          },
        ),
        const SizedBox(width: 16),
        StreamBuilder<PlaybackState>(
          stream: audioController.playbackState,
          builder: (context, snapshot) {
            final repeatMode =
                snapshot.data?.repeatMode ?? AudioServiceRepeatMode.none;
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: repeatMode == AudioServiceRepeatMode.one
                  ? const AdwaitaIcon(
                      AdwaitaIcons.media_playlist_repeat_song,
                    )
                  : const AdwaitaIcon(
                      AdwaitaIcons.media_playlist_repeat,
                    ),
              iconSize: widget.largeControlsButton ? 24.0 : 20.0,
              color: repeatMode != AudioServiceRepeatMode.none
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              onPressed: () async {
                switch (repeatMode) {
                  case AudioServiceRepeatMode.none:
                    await audioController
                        .setRepeatMode(AudioServiceRepeatMode.all);
                    break;
                  case AudioServiceRepeatMode.all:
                    await audioController
                        .setRepeatMode(AudioServiceRepeatMode.one);
                    break;
                  case AudioServiceRepeatMode.one:
                    await audioController
                        .setRepeatMode(AudioServiceRepeatMode.none);
                    break;
                  default:
                }
              },
            );
          },
        )
      ],
    );
  }
}
