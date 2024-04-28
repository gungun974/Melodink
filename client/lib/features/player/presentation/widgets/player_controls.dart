import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
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
  final _audioHandler = sl<AudioHandler>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        bool isShuffled = false;

        if (state is PlayerPlaying) {
          isShuffled = state.isShuffled;
        }

        return Row(
          mainAxisAlignment: widget.smallControlsButton
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const Key("shuffleButton"),
              padding: const EdgeInsets.only(),
              icon: const AdwaitaIcon(
                AdwaitaIcons.media_playlist_shuffle,
              ),
              color: isShuffled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              iconSize: widget.smallControlsButton ? 20.0 : 24.0,
              onPressed: () {
                BlocProvider.of<PlayerCubit>(context).toogleShufle();
              },
            ),
            IconButton(
              key: const Key("previousButton"),
              padding: const EdgeInsets.only(),
              icon: const AdwaitaIcon(AdwaitaIcons.media_skip_backward),
              iconSize: widget.smallControlsButton ? 20.0 : 28.0,
              onPressed: () async {
                _audioHandler.skipToPrevious();
              },
            ),
            StreamBuilder<PlaybackState>(
                stream: _audioHandler.playbackState,
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
                        _audioHandler.pause();
                        return;
                      }
                      _audioHandler.play();
                    },
                  );
                }),
            IconButton(
              key: const Key("nextButton"),
              padding: const EdgeInsets.only(),
              icon: const AdwaitaIcon(AdwaitaIcons.media_skip_forward),
              iconSize: widget.smallControlsButton ? 20.0 : 28.0,
              onPressed: () async {
                _audioHandler.skipToNext();
              },
            ),
            StreamBuilder<PlaybackState>(
              stream: _audioHandler.playbackState,
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
                        _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
                        break;
                      case AudioServiceRepeatMode.all:
                        _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
                        break;
                      case AudioServiceRepeatMode.one:
                        _audioHandler
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
      },
    );
  }
}
