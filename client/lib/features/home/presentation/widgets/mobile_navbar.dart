import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/routes/provider.dart';

class MobileNavbar extends ConsumerWidget {
  const MobileNavbar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUrl = ref.watch(appRouterCurrentUrl);

    return BottomAppBar(
      color: Colors.black87,
      height: 56,
      child: Row(
        children: [
          MobileNavbarItem(
            label: 'Search',
            icon: const AdwaitaIcon(
              AdwaitaIcons.system_search,
              size: 24,
            ),
            onTap: () {
              GoRouter.of(context).go("/track");
            },
            active: currentUrl == "/track",
          ),
          MobileNavbarItem(
            label: 'Library',
            icon: const AdwaitaIcon(
              AdwaitaIcons.library_music,
              size: 24,
            ),
            onTap: () {
              GoRouter.of(context).go("/album");
            },
            active: currentUrl == "/album",
          ),
          MobileNavbarItem(
            label: 'Settings',
            icon: const AdwaitaIcon(
              AdwaitaIcons.gear,
              size: 24,
            ),
            onTap: () {
              GoRouter.of(context).go("/settings");
            },
            active: currentUrl == "/settings",
          ),
        ],
      ),
    );
  }
}

class MobileNavbarItem extends StatelessWidget {
  final String label;

  final Widget icon;

  final GestureTapCallback? onTap;

  final bool active;

  const MobileNavbarItem({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: color,
                ),
                child: icon,
              ),
              const SizedBox(height: 3.0),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 13 * 0.03,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
