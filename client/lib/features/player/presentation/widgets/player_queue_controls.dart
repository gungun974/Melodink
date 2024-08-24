import 'package:flutter/material.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
import 'package:melodink_client/features/player/presentation/widgets/tiny_player_seeker.dart';

class PlayerQueueControls extends StatelessWidget {
  const PlayerQueueControls({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      constraints: const BoxConstraints(maxWidth: 512 + 32),
      child: IntrinsicHeight(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 0, 0, 0.03),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    8,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: const PlayerControls(largeControlsButton: true),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: TinyPlayerSeeker(),
            )
          ],
        ),
      ),
    );
  }
}
