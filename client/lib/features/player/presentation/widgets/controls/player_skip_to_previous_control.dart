import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:provider/provider.dart';

class PlayerSkipToPreviousControl extends StatelessWidget {
  final bool largeControlButton;

  const PlayerSkipToPreviousControl({
    super.key,
    this.largeControlButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    return AppIconButton(
      padding: const EdgeInsets.all(8),
      icon: const AdwaitaIcon(AdwaitaIcons.media_skip_backward),
      iconSize: largeControlButton ? 28.0 : 20.0,
      onPressed: () async {
        await audioController.skipToPrevious();
      },
    );
  }
}
