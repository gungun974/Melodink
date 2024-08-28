import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/routes/provider.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/features/home/presentation/widgets/desktop_sidebar.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';

class DesktopPlayerBar extends StatelessWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.black,
      child: Row(
        children: [
          const SizedBox(
            width: DesktopSidebar.width,
            child: PlayerControls(),
          ),
          const Expanded(child: LargePlayerSeeker()),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Row(
              children: [
                const AdwaitaIcon(
                  AdwaitaIcons.heart_outline_thick,
                  size: 20.0,
                ),
                const SizedBox(width: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final currentUrl = ref.watch(appRouterCurrentUrl);

                    return IconButton(
                      padding: const EdgeInsets.only(right: 4),
                      constraints: const BoxConstraints(),
                      icon: const AdwaitaIcon(
                        AdwaitaIcons.music_queue,
                        size: 20.0,
                      ),
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
          )
        ],
      ),
    );
  }
}
