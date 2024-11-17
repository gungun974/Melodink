import 'dart:io';

import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:popover/popover.dart';

class VolumeControl extends ConsumerWidget {
  final bool largeControlButton;

  const VolumeControl({
    super.key,
    this.largeControlButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final externalVolume = ref.watch(currentPlayerVolumeProvider);
    final currentTrack = ref.watch(currentTrackStreamProvider);

    if (currentTrack.valueOrNull == null) {
      return const SizedBox.shrink();
    }

    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return const SizedBox.shrink();
    }

    return AppIconButton(
      padding: const EdgeInsets.all(8),
      icon: AdwaitaIcon(
        switch (externalVolume) {
          <= 0 => AdwaitaIcons.audio_volume_muted,
          <= 33 => AdwaitaIcons.audio_volume_low,
          <= 66 => AdwaitaIcons.audio_volume_medium,
          _ => AdwaitaIcons.audio_volume_high
        },
      ),
      iconSize: largeControlButton ? 20.0 : 16.0,
      color: Colors.white,
      onPressed: () async {
        final _ = ref.refresh(currentPlayerVolumeProvider);
        showPopover(
          context: context,
          bodyBuilder: (context) => Consumer(
            builder: (context, ref, child) {
              final volume = ref.watch(currentPlayerVolumeProvider);

              return RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  onChanged: (value) {
                    audioController.setVolume(value);
                    final _ = ref.refresh(currentPlayerVolumeProvider);
                  },
                  value: volume,
                  min: 0,
                  max: 100,
                ),
              );
            },
          ),
          direction: PopoverDirection.top,
          width: 50,
          height: 190,
          arrowHeight: 0,
          arrowWidth: 0,
          barrierColor: Colors.transparent,
          backgroundColor: Colors.black,
        );
      },
    );
  }
}
