import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesktopSideNavbar extends StatelessWidget {
  final String location;

  const DesktopSideNavbar({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.08),
      width: 72 * 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopSideNavbarItem(
            label: "Tracks",
            icon: const AdwaitaIcon(
              AdwaitaIcons.playlist2,
              size: 22.0,
            ),
            onTap: () {
              GoRouter.of(context).go("/tracks");
            },
            active: location == "/tracks",
          ),
          DesktopSideNavbarItem(
            label: "Search",
            icon: const AdwaitaIcon(
              AdwaitaIcons.edit_find,
              size: 19.0,
            ),
            onTap: () {
              GoRouter.of(context).go("/search");
            },
            active: location == "/search",
          ),
          DesktopSideNavbarItem(
            label: "Library",
            icon: const AdwaitaIcon(
              AdwaitaIcons.library_music,
              size: 19.0,
            ),
            onTap: () {
              GoRouter.of(context).go("/library");
            },
            active: location == "/library",
          ),
          // Text("Search"),
          // Text("Library"),
          // Divider(),
          // Text("+ Playlist"),
          // Divider(),
          // Text("Lister toute les playlist utilistateur"),
        ],
      ),
    );
  }
}

class DesktopSideNavbarItem extends StatelessWidget {
  final String label;

  final Widget icon;

  final GestureTapCallback? onTap;

  final bool active;

  const DesktopSideNavbarItem({
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
        color: const Color.fromRGBO(0, 0, 0, 0.12),
        padding: const EdgeInsets.symmetric(
          vertical: 14.0,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24.0 + 24 * 1.5,
              child: IconTheme(
                data: IconThemeData(
                  color: color,
                ),
                child: icon,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
