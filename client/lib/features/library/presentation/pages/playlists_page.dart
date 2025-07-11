import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_provider.dart';
import 'package:melodink_client/features/library/presentation/modals/create_playlist_modal.dart';
import 'package:melodink_client/features/library/presentation/widgets/playlist_collections_grid.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlaylists = ref.watch(allPlaylistsProvider);

    final playlists = asyncPlaylists.valueOrNull;

    if (playlists == null) {
      return Container();
    }

    return AppScreenTypeLayoutBuilder(builder: (context, size) {
      final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
      final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

      return CustomScrollView(
        slivers: [
          SliverContainer(
            maxWidth: maxWidth,
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: 16.0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    "${t.general.playlists} ",
                    style: const TextStyle(
                      fontSize: 48,
                      letterSpacing: 48 * 0.03,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "(${playlists.length})",
                    style: const TextStyle(
                      fontSize: 35,
                      letterSpacing: 35 * 0.03,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (size == AppScreenTypeLayout.desktop)
                    AppButton(
                      text: t.actions.newPlaylist,
                      type: AppButtonType.primary,
                      onPressed: () {
                        CreatePlaylistModal.showModal(context);
                      },
                    ),
                  if (size == AppScreenTypeLayout.mobile)
                    AppIconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFC47ED0),
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                        child: Center(
                          child: AdwaitaIcon(
                            size: 20,
                            AdwaitaIcons.list_add,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      iconSize: 42,
                      onPressed: () {
                        CreatePlaylistModal.showModal(context);
                      },
                    ),
                ],
              ),
            ),
          ),
          SliverContainer(
            maxWidth: maxWidth,
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: 16.0,
            ),
            sliver: PlaylistCollectionsGrid(
              playlists: playlists,
            ),
          ),
        ],
      );
    });
  }
}
