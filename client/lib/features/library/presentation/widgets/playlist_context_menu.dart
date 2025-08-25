import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/playlist_context_menu_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class PlaylistContextMenu extends StatelessWidget {
  const PlaylistContextMenu({
    super.key,
    required this.playlist,
    required this.menuController,
    required this.child,
    this.customActionsBuilder,
  });

  final Playlist playlist;

  final MenuController menuController;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    Playlist playlist,
  )?
  customActionsBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PlaylistContextMenuViewModel(
        eventBus: context.read(),
        audioController: context.read(),
        playlistRepository: context.read(),
      )..loadPlaylist(playlist),
      child: Builder(
        builder: (providerContext) {
          return AutoCloseContextMenuOnScroll(
            menuController: menuController,
            child: Stack(
              children: [
                MenuAnchor(
                  clipBehavior: Clip.antiAlias,
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const AdwaitaIcon(
                        AdwaitaIcons.playlist,
                        size: 20,
                      ),
                      child: Text(t.actions.addToQueue),
                      onPressed: () {
                        providerContext
                            .read<PlaylistContextMenuViewModel>()
                            .addToQueue(providerContext);

                        menuController.close();
                      },
                    ),
                    MenuItemButton(
                      leadingIcon: const AdwaitaIcon(
                        AdwaitaIcons.media_playlist_shuffle,
                        size: 20,
                      ),
                      child: Text(t.actions.randomAddToQueue),
                      onPressed: () {
                        providerContext
                            .read<PlaylistContextMenuViewModel>()
                            .addToQueueRandomly(providerContext);

                        menuController.close();
                      },
                    ),
                    const Divider(height: 8),
                    MenuItemButton(
                      leadingIcon: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: AdwaitaIcon(AdwaitaIcons.edit, size: 16),
                      ),
                      child: Text(t.general.edit),
                      onPressed: () {
                        providerContext
                            .read<PlaylistContextMenuViewModel>()
                            .editPlaylist(providerContext);

                        menuController.close();
                      },
                    ),
                    MenuItemButton(
                      leadingIcon: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: AdwaitaIcon(AdwaitaIcons.edit_copy, size: 16),
                      ),
                      child: Text(t.general.duplicate),
                      onPressed: () {
                        providerContext
                            .read<PlaylistContextMenuViewModel>()
                            .duplicatePlaylist(providerContext);

                        menuController.close();
                      },
                    ),
                    if (customActionsBuilder != null)
                      ...customActionsBuilder!(
                        context,
                        menuController,
                        playlist,
                      ),
                  ],
                  controller: menuController,
                ),
                child,
              ],
            ),
          );
        },
      ),
    );
  }
}
