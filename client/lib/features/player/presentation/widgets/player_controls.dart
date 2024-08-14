import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/injection_container.dart';

class PlayerControls extends StatefulWidget {
  final bool smallControlsButton;

  const PlayerControls({
    super.key,
    this.smallControlsButton = true,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  final AudioController audioController = sl();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.smallControlsButton
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        StreamBuilder(
            stream: audioController.playbackState,
            builder: (context, snapshot) {
              return IconButton(
                key: const Key("shuffleButton"),
                padding: const EdgeInsets.only(),
                icon: const AdwaitaIcon(
                  AdwaitaIcons.media_playlist_shuffle,
                ),
                color: snapshot.data?.shuffleMode == AudioServiceShuffleMode.all
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                iconSize: widget.smallControlsButton ? 20.0 : 24.0,
                onPressed: () async {
                  await audioController.toogleShufle();
                },
              );
            }),
        IconButton(
          key: const Key("previousButton"),
          padding: const EdgeInsets.only(),
          icon: const AdwaitaIcon(AdwaitaIcons.media_skip_backward),
          iconSize: widget.smallControlsButton ? 20.0 : 28.0,
          onPressed: () async {
            await audioController.skipToPrevious();
          },
        ),
        StreamBuilder<PlaybackState>(
            stream: audioController.playbackState,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data?.playing ?? false;
              return IconButton(
                key: const Key("playButton"),
                padding: const EdgeInsets.only(),
                icon: isPlaying
                    ? const AdwaitaIcon(AdwaitaIcons.media_playback_pause)
                    : const AdwaitaIcon(AdwaitaIcons.media_playback_start),
                iconSize: widget.smallControlsButton ? 34.0 : 52.0,
                onPressed: () async {
                  if (isPlaying) {
                    await audioController.pause();
                    return;
                  }
                  await audioController.play();
                },
              );
            }),
        IconButton(
          key: const Key("nextButton"),
          padding: const EdgeInsets.only(),
          icon: const AdwaitaIcon(AdwaitaIcons.media_skip_forward),
          iconSize: widget.smallControlsButton ? 20.0 : 28.0,
          onPressed: () async {
            await audioController.skipToNext();
          },
        ),
        StreamBuilder<PlaybackState>(
          stream: audioController.playbackState,
          builder: (context, snapshot) {
            final repeatMode =
                snapshot.data?.repeatMode ?? AudioServiceRepeatMode.none;
            return IconButton(
              key: const Key("repeatButton"),
              padding: const EdgeInsets.only(),
              icon: repeatMode == AudioServiceRepeatMode.one
                  ? const AdwaitaIcon(
                      AdwaitaIcons.media_playlist_repeat_song,
                    )
                  : const AdwaitaIcon(
                      AdwaitaIcons.media_playlist_repeat,
                    ),
              iconSize: widget.smallControlsButton ? 20.0 : 24.0,
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
        ),
      ],
    );
  }
}
