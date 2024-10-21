import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileNavbar extends StatelessWidget {
  const MobileNavbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;

    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: AdwaitaIcon(
            AdwaitaIcons.heart_outline_thick,
          ),
          label: 'Liked songs',
        ),
        BottomNavigationBarItem(
          icon: AdwaitaIcon(
            AdwaitaIcons.system_search,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: AdwaitaIcon(
            AdwaitaIcons.library_music,
          ),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: AdwaitaIcon(
            AdwaitaIcons.gear,
          ),
          label: 'Settings',
        ),
      ],
      currentIndex: currentIndex,
      selectedFontSize: 13.0,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedFontSize: 13.0,
      backgroundColor: Colors.black87,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        switch (index) {
          case 0:
            GoRouter.of(context).go("/liked");
            break;
          case 1:
            GoRouter.of(context).go("/track");
            break;
          case 2:
            GoRouter.of(context).go("/album");
            break;
          case 3:
            GoRouter.of(context).go("/settings");
            break;
        }
      },
    );
  }
}
