import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_seeker.dart';
import 'package:melodink_client/injection_container.dart';

class PlayerControls extends StatefulWidget {
  const PlayerControls({super.key});

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  final _audioHandler = sl<AudioHandler>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  padding: const EdgeInsets.only(),
                  icon: const AdwaitaIcon(AdwaitaIcons.media_playlist_shuffle),
                  iconSize: 20.0,
                  onPressed: () {},
                ),
                IconButton(
                  padding: const EdgeInsets.only(),
                  icon: const AdwaitaIcon(AdwaitaIcons.media_skip_backward),
                  iconSize: 20.0,
                  onPressed: () async {
                    _audioHandler.skipToPrevious();
                  },
                ),
                StreamBuilder<PlaybackState>(
                    stream: _audioHandler.playbackState,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return IconButton(
                        padding: const EdgeInsets.only(),
                        icon: isPlaying
                            ? const AdwaitaIcon(
                                AdwaitaIcons.media_playback_pause)
                            : const AdwaitaIcon(
                                AdwaitaIcons.media_playback_start),
                        iconSize: 34.0,
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
                  padding: const EdgeInsets.only(),
                  icon: const AdwaitaIcon(AdwaitaIcons.media_skip_forward),
                  iconSize: 20.0,
                  onPressed: () async {
                    _audioHandler.skipToNext();
                  },
                ),
                IconButton(
                  padding: const EdgeInsets.only(),
                  icon: const AdwaitaIcon(AdwaitaIcons.media_playlist_repeat),
                  iconSize: 20.0,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            const PlayerSeeker(),
          ],
        );
      },
    );
  }
}
