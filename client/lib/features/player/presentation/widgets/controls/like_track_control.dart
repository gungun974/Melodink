import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';

class LikeTrackControl extends StatelessWidget {
  final bool largeControlButton;

  const LikeTrackControl({
    super.key,
    this.largeControlButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      padding: const EdgeInsets.all(8),
      icon: const AdwaitaIcon(
        AdwaitaIcons.heart_outline_thick,
      ),
      iconSize: largeControlButton ? 24.0 : 20.0,
    );
  }
}
