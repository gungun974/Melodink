import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/routes/provider.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop_current_track.dart';
import 'package:melodink_client/features/player/presentation/widgets/side_player_bar.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key});

  static const smallWidth = 180.0;
  static const width = 220.0;
  static const largeWidth = 280.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUrl = ref.watch(appRouterCurrentUrl);

    final currentPlayerBarPosition =
        ref.watch(currentPlayerBarPositionProvider);

    return Container(
      width: switch (currentPlayerBarPosition) {
        AppSettingPlayerBarPosition.side => largeWidth,
        AppSettingPlayerBarPosition.center => smallWidth,
        _ => width,
      },
      color: const Color.fromRGBO(0, 0, 0, 0.08),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DesktopSidebarItem(
                    label: t.general.tracks,
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.music_note_single,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/track");
                    },
                    active: currentUrl == "/track",
                  ),
                  DesktopSidebarItem(
                    label: t.general.playlists,
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.playlist2,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/playlist");
                    },
                    active: currentUrl == "/playlist",
                  ),
                  DesktopSidebarItem(
                    label: t.general.albums,
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.media_optical,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/album");
                    },
                    active: currentUrl == "/album",
                  ),
                  DesktopSidebarItem(
                    label: t.general.artists,
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.music_artist2,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/artist");
                    },
                    active: currentUrl == "/artist",
                  ),
                  DesktopSidebarItem(
                    label: t.general.settings,
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.gear,
                      size: 24.0,
                    ),
                    onTap: () {
                      GoRouter.of(context).go("/settings");
                    },
                    active: currentUrl == "/settings",
                  ),
                ],
              ),
            ),
          ),
          if (currentPlayerBarPosition != AppSettingPlayerBarPosition.center)
            const DesktopCurrentTrack(),
          if (currentPlayerBarPosition == AppSettingPlayerBarPosition.side)
            const SidePlayerBar(),
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
