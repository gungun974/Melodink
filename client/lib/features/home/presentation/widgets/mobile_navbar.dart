import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/routes.dart';

class MobileNavbar extends StatelessWidget {
  final String location;

  const MobileNavbar({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: AdwaitaIcon(
            AdwaitaIcons.playlist2,
          ),
          label: 'Tracks',
        ),
        BottomNavigationBarItem(
          icon: AdwaitaIcon(
            AdwaitaIcons.edit_find,
            size: 18,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: AdwaitaIcon(
            AdwaitaIcons.library_music,
            size: 18,
          ),
          label: 'Library',
        ),
      ],
      currentIndex: switch (GoRouter.of(context).location) {
        "/tracks" => 0,
        "/search" => 1,
        "/library" => 2,
        _ => 0,
      },
      selectedFontSize: 13.0,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedFontSize: 13.0,
      backgroundColor: Colors.black87,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        switch (index) {
          case 0:
            GoRouter.of(context).go("/tracks");
            break;
          case 1:
            GoRouter.of(context).go("/search");
            break;
          case 2:
            GoRouter.of(context).go("/library");
            break;
        }
      },
    );
  }
}
