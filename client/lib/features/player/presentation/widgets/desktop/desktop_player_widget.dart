import 'package:flutter/material.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop/current_track_info.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop/player_more_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_seeker.dart';

class DesktopPlayerWidget extends StatelessWidget {
  final String location;

  const DesktopPlayerWidget({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Expanded(
            flex: 1,
            child: CurrentTrackInfo(),
          ),
          const Column(
            children: [
              PlayerControls(),
              SizedBox(height: 4.0),
              PlayerSeeker(),
            ],
          ),
          Expanded(
            flex: 1,
            child: PlayerMoreControls(
              location: location,
            ),
          ),
        ],
      ),
    );
  }
}
