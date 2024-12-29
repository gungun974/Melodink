import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/album_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/album_collections_grid.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:popover/popover.dart';

class AlbumsPage extends HookConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlbums = ref.watch(allSearchAlbumsProvider);

    final searchTextController =
        useTextEditingController(text: ref.watch(allAlbumsSearchInputProvider));

    ref.watch(allAlbumsSortedModeProvider);

    final albums = asyncAlbums.valueOrNull;

    if (albums == null) {
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
                      Text(
                        "(${albums.length})",
                        style: const TextStyle(
                          fontSize: 35,
                          letterSpacing: 35 * 0.03,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextFormField(
                          labelText: t.general.search,
                          prefixIcon: const AdwaitaIcon(
                            size: 20,
                            AdwaitaIcons.system_search,
                          ),
                          controller: searchTextController,
                          onChanged: (value) => ref
                              .read(allAlbumsSearchInputProvider.notifier)
                              .state = value,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Builder(
                        builder: (context) {
                          return AppButton(
                            text: t.general.sort,
                            type: AppButtonType.primary,
                            onPressed: () {
                              showPopover(
                                context: context,
                                bodyBuilder: (context) =>
                                    const AlbumsSortedPopup(),
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
                  )
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
            sliver: AlbumCollectionsGrid(
              albums: albums,
            ),
          ),
        ],
      );
    });
  }
}

class AlbumsSortedPopup extends ConsumerWidget {
  const AlbumsSortedPopup({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedMode = ref.watch(allAlbumsSortedModeProvider);

    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: Column(
          children: [
            RadioListTile(
              title: Text(t.sorting.newest),
              value: "newest",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allAlbumsSortedModeProvider.notifier).state = "newest";
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(t.sorting.oldest),
              value: "oldest",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allAlbumsSortedModeProvider.notifier).state = "oldest";
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(t.sorting.albumsAz),
              value: "name-az",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allAlbumsSortedModeProvider.notifier).state =
                    "name-az";
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(t.sorting.albumsZa),
              value: "name-za",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allAlbumsSortedModeProvider.notifier).state =
                    "name-za";
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(t.sorting.artistsAz),
              value: "artist-az",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allAlbumsSortedModeProvider.notifier).state =
                    "artist-az";
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(t.sorting.artistsZa),
              value: "artist-za",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allAlbumsSortedModeProvider.notifier).state =
                    "artist-za";
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
