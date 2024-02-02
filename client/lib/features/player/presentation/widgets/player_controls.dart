import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_seeker.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

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
                  onPressed: () {},
                ),
                StreamBuilder<bool>(
                    stream: BlocProvider.of<PlayerCubit>(context)
                        .player
                        .playingStream,
                    builder: (context, snapshot) {
                      return IconButton(
                        padding: const EdgeInsets.only(),
                        icon: snapshot.data ?? false
                            ? const AdwaitaIcon(
                                AdwaitaIcons.media_playback_pause)
                            : const AdwaitaIcon(
                                AdwaitaIcons.media_playback_start),
                        iconSize: 34.0,
                        onPressed: () async {
                          BlocProvider.of<PlayerCubit>(context).playOrPause();
                        },
                      );
                    }),
                IconButton(
                  padding: const EdgeInsets.only(),
                  icon: const AdwaitaIcon(AdwaitaIcons.media_skip_forward),
                  iconSize: 20.0,
                  onPressed: () {},
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
            PlayerSeeker(
              player: BlocProvider.of<PlayerCubit>(context).player,
            )
          ],
        );
      },
    );
  }
}
