import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/form/app_search_form_field.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/providers/artist_provider.dart';
import 'package:melodink_client/features/library/presentation/widgets/artist_collections_grid.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:popover/popover.dart';

class ArtistsPage extends HookConsumerWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArtists = ref.watch(allSearchArtistsProvider);

    final searchTextController = useTextEditingController(
        text: ref.watch(allArtistsSearchInputProvider));

    ref.watch(allArtistsSortedModeProvider);

    final artists = asyncArtists.valueOrNull;

    if (artists == null) {
      return Container();
    }

    return AppScreenTypeLayoutBuilder(
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
                        "${t.general.artists} ",
                        style: const TextStyle(
                          fontSize: 48,
                          letterSpacing: 48 * 0.03,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "(${artists.length})",
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
                        child: AppSearchFormField(
                          controller: searchTextController,
                          onChanged: (value) => ref
                              .read(allArtistsSearchInputProvider.notifier)
                              .state = value,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Builder(builder: (context) {
                        return AppButton(
                          text: t.general.sort,
                          type: AppButtonType.primary,
                          onPressed: () {
                            showPopover(
                              context: context,
                              bodyBuilder: (context) =>
                                  const ArtistsSortedPopup(),
                              direction: PopoverDirection.bottom,
                              arrowDyOffset: 8,
                              arrowHeight: 0,
                              arrowWidth: 0,
                              barrierColor: Colors.transparent,
                              backgroundColor: Colors.black,
                            );
                          },
                        );
                      }),
                    ],
                  )
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
                    sliver: ArtistCollectionsGrid(
                      artists: artists,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ArtistsSortedPopup extends ConsumerWidget {
  const ArtistsSortedPopup({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedMode = ref.watch(allArtistsSortedModeProvider);

    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: Column(
          children: [
            RadioListTile(
              title: Text(t.sorting.newest),
              value: "newest",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allArtistsSortedModeProvider.notifier).state =
                    "newest";
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(t.sorting.oldest),
              value: "oldest",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allArtistsSortedModeProvider.notifier).state =
                    "oldest";
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(t.sorting.artistsAz),
              value: "name-az",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allArtistsSortedModeProvider.notifier).state =
                    "name-az";
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(t.sorting.artistsZa),
              value: "name-za",
              groupValue: sortedMode,
              onChanged: (value) {
                ref.read(allArtistsSortedModeProvider.notifier).state =
                    "name-za";
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
