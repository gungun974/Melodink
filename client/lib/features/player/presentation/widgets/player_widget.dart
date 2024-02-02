import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';

import 'current_track_info.dart';

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: const Row(
        children: [
          Expanded(
            flex: 1,
            child: CurrentTrackInfo(),
          ),
          PlayerControls(),
          Expanded(
            flex: 1,
            child: MoreControls(),
          ),
        ],
      ),
    );
  }
}

class MoreControls extends StatelessWidget {
  const MoreControls({super.key});

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
          onPressed: () {},
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
