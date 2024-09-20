import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/routes/provider.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
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
            padding: const EdgeInsets.only(left: 12, right: 18),
            child: Row(
              children: [
                const AppIconButton(
                  padding: EdgeInsets.all(8),
                  icon: AdwaitaIcon(
                    AdwaitaIcons.heart_outline_thick,
                  ),
                  iconSize: 20.0,
                ),
                SizedBox(width: 2),
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
          )
        ],
      ),
    );
  }
}
