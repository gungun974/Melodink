import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/album_context_menu_viewmodel.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/playlists_context_menu_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class AlbumContextMenu extends StatelessWidget {
  const AlbumContextMenu({
    super.key,
    required this.album,
    required this.menuController,
    required this.child,
    this.customActionsBuilder,
  });

  final Album album;

  final MenuController menuController;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    Album album,
  )?
  customActionsBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => PlaylistsContextMenuViewModel(
            eventBus: context.read(),
            playlistRepository: context.read(),
          )..loadPlaylists(),
        ),
        ChangeNotifierProvider(
          create: (context) => AlbumContextMenuViewModel(
            audioController: context.read(),
            albumRepository: context.read(),
            playlistsContextMenuViewModel: context.read(),
          )..loadAlbum(album),
        ),
      ],
      child: Builder(
        builder: (providerContext) {
          return AutoCloseContextMenuOnScroll(
            menuController: menuController,
            child: Stack(
              children: [
                MenuAnchor(
                  clipBehavior: Clip.antiAlias,
                  menuChildren: [
                    Consumer<PlaylistsContextMenuViewModel>(
                      builder: (context, viewModel, _) {
                        return SubmenuButton(
                          leadingIcon: const AdwaitaIcon(
                            AdwaitaIcons.playlist2,
                            size: 20,
                          ),
                          menuChildren: [
                            MenuItemButton(
                              child: Text(t.actions.newPlaylist),
                              onPressed: () {
                                providerContext
                                    .read<AlbumContextMenuViewModel>()
                                    .newPlaylist(providerContext);

                                menuController.close();
                              },
                            ),
                            const Divider(height: 0),
                            ...viewModel.playlists.map((playlist) {
                              return MenuItemButton(
                                child: Text(playlist.name),
                                onPressed: () {
                                  providerContext
                                      .read<AlbumContextMenuViewModel>()
                                      .addToPlaylist(providerContext, playlist);

                                  menuController.close();
                                },
                              );
                            }),
                          ],
                          child: Text(t.actions.addToPlaylist),
                        );
                      },
                    ),
                    MenuItemButton(
                      leadingIcon: const AdwaitaIcon(
                        AdwaitaIcons.playlist,
                        size: 20,
                      ),
                      child: Text(t.actions.addToQueue),
                      onPressed: () async {
                        providerContext
                            .read<AlbumContextMenuViewModel>()
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
                            .read<AlbumContextMenuViewModel>()
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
                            .read<AlbumContextMenuViewModel>()
                            .editAlbum(providerContext);

                        menuController.close();
                      },
                    ),
                    if (customActionsBuilder != null)
                      ...customActionsBuilder!(context, menuController, album),
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
