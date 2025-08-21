import 'dart:io';

import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/hooks/use_behavior_subject_stream.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:popover/popover.dart';

class VolumeControl extends HookConsumerWidget {
  final bool largeControlButton;

  const VolumeControl({super.key, this.largeControlButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.read(audioControllerProvider);
    final currentTrack = useBehaviorSubjectStream(audioController.currentTrack);

    final refresh = useState(UniqueKey());

    if (currentTrack.data == null) {
      return const SizedBox.shrink();
    }

    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return const SizedBox.shrink();
    }

    return AppIconButton(
      padding: const EdgeInsets.all(8),
      icon: AdwaitaIcon(switch (audioController.getVolume()) {
        <= 0 => AdwaitaIcons.audio_volume_muted,
        <= 33 => AdwaitaIcons.audio_volume_low,
        <= 66 => AdwaitaIcons.audio_volume_medium,
        _ => AdwaitaIcons.audio_volume_high,
      }),
      iconSize: largeControlButton ? 20.0 : 16.0,
      color: Colors.white,
      onPressed: () async {
        showPopover(
          context: context,
          bodyBuilder: (context) => HookBuilder(
            builder: (context) {
              final volume = useState(audioController.getVolume());
              return RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  onChanged: (value) {
                    audioController.setVolume(value);
                    volume.value = value;
                    refresh.value = UniqueKey();
                  },
                  value: volume.value,
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
