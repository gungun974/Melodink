import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class MobileNavbar extends HookWidget {
  const MobileNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUrl = useValueListenable(
      context.read<AppRouter>().currentUrlNotifier,
    );

    return BottomAppBar(
      color: Colors.black87,
      height: 56,
      child: Row(
        children: [
          MobileNavbarItem(
            label: t.general.tracks,
            icon: const AdwaitaIcon(AdwaitaIcons.music_note_single, size: 24),
            onTap: () {
              GoRouter.of(context).go("/track");
            },
            active: currentUrl == "/track",
          ),
          MobileNavbarItem(
            label: t.general.playlists,
            icon: const AdwaitaIcon(AdwaitaIcons.playlist2, size: 24),
            onTap: () {
              GoRouter.of(context).go("/playlist");
            },
            active: currentUrl == "/playlist",
          ),
          MobileNavbarItem(
            label: t.general.albums,
            icon: const AdwaitaIcon(AdwaitaIcons.media_optical, size: 24),
            onTap: () {
              GoRouter.of(context).go("/album");
            },
            active: currentUrl == "/album",
          ),
          MobileNavbarItem(
            label: t.general.artists,
            icon: const AdwaitaIcon(AdwaitaIcons.music_artist2, size: 24),
            onTap: () {
              GoRouter.of(context).go("/artist");
            },
            active: currentUrl == "/artist",
          ),
          MobileNavbarItem(
            label: t.general.settings,
            icon: const AdwaitaIcon(AdwaitaIcons.gear, size: 24),
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
                data: IconThemeData(color: color),
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
