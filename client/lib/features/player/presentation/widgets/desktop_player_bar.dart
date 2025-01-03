import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/routes/provider.dart';
import 'package:melodink_client/features/home/presentation/widgets/desktop_sidebar.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/like_track_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/open_queue_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/volume_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';

class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUrl = ref.watch(appRouterCurrentUrl);
    final scoringSystem = ref.watch(currentScoringSystemProvider);

    final currentPlayerBarPosition =
        ref.watch(currentPlayerBarPositionProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: currentUrl != "/player" ? 60 : 0,
      curve: Curves.easeInOutQuad,
      child: OverflowBox(
        alignment: currentPlayerBarPosition == AppSettingPlayerBarPosition.top
            ? Alignment.bottomCenter
            : Alignment.topCenter,
        maxHeight: double.infinity,
        child: Container(
          height: 60,
          color: Colors.black,
          child: Row(
            children: [
              SizedBox(
                width: DesktopSidebar.width,
                child: PlayerControls(),
              ),
              Expanded(child: LargePlayerSeeker()),
              Padding(
                padding: EdgeInsets.only(left: 12, right: 18),
                child: Row(
                  children: [
                    if (scoringSystem != AppSettingScoringSystem.none)
                      CurrentTrackScoreControl(),
                    if (scoringSystem != AppSettingScoringSystem.none)
                      SizedBox(width: 10),
                    VolumeControl(),
                    SizedBox(width: 2),
                    OpenQueueControl(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
