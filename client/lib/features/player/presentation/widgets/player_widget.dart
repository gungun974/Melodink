import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';

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

class CurrentTrackInfo extends StatelessWidget {
  const CurrentTrackInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.network(
          "https://i.scdn.co/image/ab67616d00001e027723a365cb5b70c6f37fabe3",
          height: 64.0,
          width: 64.0,
          fit: BoxFit.cover,
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Artist',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
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
            IconButton(
              padding: const EdgeInsets.only(),
              icon: const AdwaitaIcon(AdwaitaIcons.media_playback_start),
              iconSize: 34.0,
              onPressed: () {},
            ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '0:00',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              height: 5.0,
              width: MediaQuery.of(context).size.width * 0.325,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(width: 8.0),
            const Text(
              '0:00',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
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
