import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';

class PlayerSkipToNextControl extends ConsumerWidget {
  final bool largeControlButton;

  const PlayerSkipToNextControl({
    super.key,
    this.largeControlButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return AppIconButton(
      padding: const EdgeInsets.all(8),
      icon: const AdwaitaIcon(AdwaitaIcons.media_skip_forward),
      iconSize: largeControlButton ? 28.0 : 20.0,
      onPressed: () async {
        await audioController.skipToNext();
      },
    );
  }
}
