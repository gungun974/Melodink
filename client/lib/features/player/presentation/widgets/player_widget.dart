import 'package:flutter/material.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop/desktop_player_widget.dart';
import 'package:melodink_client/features/player/presentation/widgets/mobile/mobile_player_widget.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AudioPlayerWidget extends StatelessWidget {
  final String location;

  const AudioPlayerWidget({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (
      context,
      sizingInformation,
    ) {
      if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
        return DesktopPlayerWidget(
          location: location,
        );
      }
      return const MobilePlayerWidget();
    });
  }
}
