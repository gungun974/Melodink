import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/form/app_search_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/albums_viewmodel.dart';
import 'package:melodink_client/features/library/presentation/widgets/album_collections_grid.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

class AlbumsPage extends HookWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AlbumsViewModel(
        eventBus: context.read(),
        albumRepository: context.read(),
      )..loadAlbums(),
      child: AppScreenTypeLayoutBuilder(
        builder: (context, size) {
          final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
          final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

          return Column(
            children: [
              MaxContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "${t.general.albums} ",
                          style: const TextStyle(
                            fontSize: 48,
                            letterSpacing: 48 * 0.03,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Consumer<AlbumsViewModel>(
                          builder: (context, viewModel, _) {
                            return Text(
                              "(${viewModel.searchAlbums.length})",
                              style: const TextStyle(
                                fontSize: 35,
                                letterSpacing: 35 * 0.03,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AppSearchFormField(
                            controller: context
                                .read<AlbumsViewModel>()
                                .searchTextController,
                            onChanged: (value) =>
                                context.read<AlbumsViewModel>().updateSearch(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Builder(
                          builder: (context) {
                            final viewModel = context.read<AlbumsViewModel>();
                            return AppButton(
                              text: t.general.sort,
                              type: AppButtonType.primary,
                              onPressed: () {
                                showPopover(
                                  context: context,
                                  bodyBuilder: (context) =>
                                      ChangeNotifierProvider.value(
                                        value: viewModel,
                                        child: const AlbumsSortedPopup(),
                                      ),
                                  direction: PopoverDirection.bottom,
                                  arrowDyOffset: 8,
                                  arrowHeight: 0,
                                  arrowWidth: 0,
                                  barrierColor: Colors.transparent,
                                  backgroundColor: Colors.black,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverContainer(
                      maxWidth: maxWidth,
                      padding: EdgeInsets.only(
                        left: padding,
                        right: padding,
                        top: 16.0,
                      ),
                      sliver: Consumer<AlbumsViewModel>(
                        builder: (context, viewModel, _) {
                          return AlbumCollectionsGrid(
                            albums: viewModel.searchAlbums,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AlbumsSortedPopup extends StatelessWidget {
  const AlbumsSortedPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: Selector<AlbumsViewModel, AlbumsSortMode>(
          selector: (_, viewModel) => viewModel.sortMode,
          builder: (context, sortMode, _) {
            return Column(
              children: [
                RadioListTile(
                  title: Text(t.sorting.newest),
                  value: AlbumsSortMode.newest,
                  groupValue: sortMode,
                  onChanged: (value) {
                    context.read<AlbumsViewModel>().setSortMode(
                      AlbumsSortMode.newest,
                    );
                    Navigator.pop(context);
                  },
                ),
                RadioListTile(
                  title: Text(t.sorting.oldest),
                  value: AlbumsSortMode.oldest,
                  groupValue: sortMode,
                  onChanged: (value) {
                    context.read<AlbumsViewModel>().setSortMode(
                      AlbumsSortMode.oldest,
                    );
                    Navigator.pop(context);
                  },
                ),
                RadioListTile(
                  title: Text(t.sorting.albumsAz),
                  value: AlbumsSortMode.nameAZ,
                  groupValue: sortMode,
                  onChanged: (value) {
                    context.read<AlbumsViewModel>().setSortMode(
                      AlbumsSortMode.nameAZ,
                    );
                    Navigator.pop(context);
                  },
                ),
                RadioListTile(
                  title: Text(t.sorting.albumsZa),
                  value: AlbumsSortMode.nameZA,
                  groupValue: sortMode,
                  onChanged: (value) {
                    context.read<AlbumsViewModel>().setSortMode(
                      AlbumsSortMode.nameZA,
                    );
                    Navigator.pop(context);
                  },
                ),
                RadioListTile(
                  title: Text(t.sorting.artistsAz),
                  value: AlbumsSortMode.artistAZ,
                  groupValue: sortMode,
                  onChanged: (value) {
                    context.read<AlbumsViewModel>().setSortMode(
                      AlbumsSortMode.artistAZ,
                    );
                    Navigator.pop(context);
                  },
                ),
                RadioListTile(
                  title: Text(t.sorting.artistsZa),
                  value: AlbumsSortMode.artistZA,
                  groupValue: sortMode,
                  onChanged: (value) {
                    context.read<AlbumsViewModel>().setSortMode(
                      AlbumsSortMode.artistZA,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
