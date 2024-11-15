import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/features/player/presentation/pages/desktop_player_page.dart';
import 'package:melodink_client/features/player/presentation/pages/mobile_player_page.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppScreenTypeLayoutBuilders(
      desktop: (_) => const DesktopPlayerPage(),
      mobile: (_) => const MobilePlayerPage(),
    );
  }
}
