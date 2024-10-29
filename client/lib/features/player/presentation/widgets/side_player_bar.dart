import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/routes/provider.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_play_pause_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_repeat_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_shuffle_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_skip_to_next_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/player_skip_to_previous_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';

class SidePlayerBar extends ConsumerWidget {
  const SidePlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackStreamProvider).valueOrNull;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: IntrinsicHeight(
                child: LargePlayerSeeker(
                  displayDurationsInBottom: true,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PlayerShuffleControl(
                  largeControlButton: false,
                ),
                PlayerSkipToPreviousControl(
                  largeControlButton: true,
                ),
                PlayerPlayPauseControl(
                  largeControlButton: true,
                ),
                PlayerSkipToNextControl(
                  largeControlButton: true,
                ),
                PlayerRepeatControl(
                  largeControlButton: false,
                ),
              ],
            ),
          ),
          Row(
            children: [
              const AppIconButton(
                padding: EdgeInsets.all(8),
                icon: AdwaitaIcon(
                  AdwaitaIcons.heart_outline_thick,
                ),
                iconSize: 20.0,
              ),
              const Spacer(),
              Consumer(
                builder: (context, ref, child) {
                  final currentUrl = ref.watch(appRouterCurrentUrl);

                  return AppIconButton(
                    padding: const EdgeInsets.all(8),
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.music_queue,
                    ),
                    iconSize: 20.0,
                    color: currentUrl == "/queue"
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    onPressed: () async {
                      if (currentUrl == "/queue") {
                        GoRouter.of(context).pop();
                        while (GoRouter.of(context)
                                .location
                                ?.startsWith("/player") ??
                            true) {
                          GoRouter.of(context).pop();
                        }
                        return;
                      }
                      GoRouter.of(context).push("/queue");
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
