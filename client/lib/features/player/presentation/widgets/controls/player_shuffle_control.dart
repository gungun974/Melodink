import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';

class PlayerShuffleControl extends ConsumerWidget {
  final bool largeControlButton;

  const PlayerShuffleControl({
    super.key,
    this.largeControlButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return StreamBuilder(
      stream: audioController.playbackState,
      builder: (context, snapshot) {
        return AppIconButton(
          padding: const EdgeInsets.all(8),
          icon: const AdwaitaIcon(
            AdwaitaIcons.media_playlist_shuffle,
          ),
          color: snapshot.data?.shuffleMode == AudioServiceShuffleMode.all
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          iconSize: largeControlButton ? 24.0 : 20.0,
          onPressed: () async {
            await audioController.toogleShufle();
          },
        );
      },
    );
  }
}
