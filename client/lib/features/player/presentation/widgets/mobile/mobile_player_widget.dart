import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/features/player/presentation/widgets/mobile/tiny_current_track_info.dart';

class MobilePlayerWidget extends StatelessWidget {
  const MobilePlayerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push("/player");
      },
      child: const TinyCurrentTrackInfo(),
    );
  }
}
