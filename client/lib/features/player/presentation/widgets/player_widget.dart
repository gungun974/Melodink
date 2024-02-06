import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';

import 'current_track_info.dart';

class AudioPlayerWidget extends StatelessWidget {
  final String location;

  const AudioPlayerWidget({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Expanded(
            flex: 1,
            child: CurrentTrackInfo(),
          ),
          const PlayerControls(),
          Expanded(
            flex: 1,
            child: MoreControls(
              location: location,
            ),
          ),
        ],
      ),
    );
  }
}

class MoreControls extends StatelessWidget {
  final String location;

  const MoreControls({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          padding: const EdgeInsets.only(),
          icon: const AdwaitaIcon(AdwaitaIcons.music_queue),
          iconSize: 20.0,
          color: Colors.white,
          onPressed: () {
            print(location);
            if (location == "/queue") {
              GoRouter.of(context).goNamed("/");
              return;
            }
            GoRouter.of(context).push("/queue");
          },
        ),
        IconButton(
          padding: const EdgeInsets.only(),
          icon: const AdwaitaIcon(AdwaitaIcons.audio_volume_high),
          iconSize: 20.0,
          color: Colors.white,
          onPressed: () {},
        ),
      ],
    );
  }
}
