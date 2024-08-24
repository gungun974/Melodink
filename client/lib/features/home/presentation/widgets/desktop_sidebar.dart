import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop_current_track.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  static const width = 220.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: const Color.fromRGBO(0, 0, 0, 0.08),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DesktopSidebarItem(
                    label: "Search",
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.system_search,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/search");
                    },
                  ),
                  DesktopSidebarItem(
                    label: "Liked songs",
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.heart_outline_thick,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/liked");
                    },
                  ),
                  DesktopSidebarItem(
                    label: "Playlists",
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.playlist2,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/playlists");
                    },
                  ),
                  DesktopSidebarItem(
                    label: "Albums",
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.media_optical,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/albums");
                    },
                  ),
                  DesktopSidebarItem(
                    label: "Artists",
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.music_artist2,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/artists");
                    },
                  ),
                  DesktopSidebarItem(
                    label: "Me",
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.person2,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/playerTest");
                    },
                  ),
                ],
              ),
            ),
          ),
          const DesktopCurrentTrack(),
        ],
      ),
    );
  }
}

class DesktopSidebarItem extends StatelessWidget {
  final String label;

  final Widget icon;

  final GestureTapCallback? onTap;

  final bool active;

  const DesktopSidebarItem({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: const Color.fromRGBO(0, 0, 0, 0.03),
        padding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 20.0,
        ),
        child: Row(
          children: [
            IconTheme(
              data: IconThemeData(
                color: color,
              ),
              child: icon,
            ),
            const SizedBox(width: 12.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w400,
                letterSpacing: 14 * 0.03,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
