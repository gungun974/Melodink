import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/modals/import_tracks_modal.dart';
import 'package:melodink_client/features/track/presentation/widgets/all_track_filter_panel.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';

class TracksPage extends HookConsumerWidget {
  const TracksPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTracks = ref.watch(allSortedTracksProvider);

    final isAutoScrollViewToCurrentTrackEnabled = ref.watch(
      isAutoScrollViewToCurrentTrackEnabledProvider,
    );

    final tracks = asyncTracks.valueOrNull;

    final scrollController = useScrollController();

    if (tracks == null) {
      return AppNavigationHeader(
        title: AppScreenTypeLayoutBuilders(
          mobile: (_) => const Text("Tracks"),
        ),
        child: Container(),
      );
    }

    return AppNavigationHeader(
      title: AppScreenTypeLayoutBuilders(
        mobile: (_) => const Text("Tracks"),
      ),
      child: AppScreenTypeLayoutBuilder(
        builder: (context, size) {
          final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
          final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

          return Column(
            children: [
              if (size == AppScreenTypeLayout.desktop)
                TracksPageSearchAndFilterHeader(
                  maxWidth: maxWidth,
                  padding: padding,
                ),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    if (size == AppScreenTypeLayout.mobile)
                      SliverToBoxAdapter(
                        child: TracksPageSearchAndFilterHeader(
                          maxWidth: maxWidth,
                          padding: padding,
                        ),
                      ),
                    SliverContainer(
                      maxWidth: maxWidth,
                      padding: EdgeInsets.only(
                        left: padding,
                        right: padding,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(0, 0, 0, 0.03),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(
                                8,
                              ),
                            ),
                          ),
                          child: size == AppScreenTypeLayout.desktop
                              ? const DesktopTrackHeader(
                                  displayDateAdded: true,
                                  displayLastPlayed: true,
                                  displayPlayedCount: true,
                                  displayQuality: true,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    SliverContainer(
                      maxWidth: maxWidth,
                      padding: EdgeInsets.only(
                        left: padding,
                        right: padding,
                      ),
                      sliver: TrackList(
                        tracks: tracks,
                        size: size,
                        displayImage: true,
                        displayAlbum: true,
                        displayDateAdded: true,
                        displayLastPlayed: true,
                        displayPlayedCount: true,
                        displayQuality: true,
                        scrollController: scrollController,
                        autoScrollToCurrentTrack:
                            isAutoScrollViewToCurrentTrackEnabled,
                        source: "Playing from Search",
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8),
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

class TracksPageSearchAndFilterHeader extends HookConsumerWidget {
  const TracksPageSearchAndFilterHeader({
    super.key,
    required this.maxWidth,
    required this.padding,
  });

  final int maxWidth;
  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchTextController =
        useTextEditingController(text: ref.watch(allTracksSearchInputProvider));

    final showFilterPanel = useState(false);

    return AppScreenTypeLayoutBuilder(
      builder: (context, size) {
        final searchField = AppTextFormField(
          labelText: "Search",
          prefixIcon: const AdwaitaIcon(
            size: 20,
            AdwaitaIcons.system_search,
          ),
          controller: searchTextController,
          onChanged: (value) =>
              ref.read(allTracksSearchInputProvider.notifier).state = value,
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: 16,
          ),
          child: Column(
            children: [
              if (size == AppScreenTypeLayout.mobile)
                if (size == AppScreenTypeLayout.mobile) searchField,
              if (size == AppScreenTypeLayout.mobile)
                const SizedBox(height: 16),
              Row(
                mainAxisAlignment: size == AppScreenTypeLayout.mobile
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                children: [
                  AppButton(
                    text: "Filter",
                    type: showFilterPanel.value
                        ? AppButtonType.primary
                        : AppButtonType.neutral,
                    onPressed: () {
                      if (showFilterPanel.value) {
                        ref
                            .read(allTracksArtistsSelectedOptionsProvider
                                .notifier)
                            .state = [];

                        ref
                            .read(
                                allTracksAlbumsSelectedOptionsProvider.notifier)
                            .state = [];
                      }

                      showFilterPanel.value = !showFilterPanel.value;
                    },
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    text: "View All",
                    type: AppButtonType.primary,
                    onPressed: () {
                      searchTextController.clear();

                      ref.read(allTracksSearchInputProvider.notifier).state =
                          "";

                      ref
                          .read(
                              allTracksArtistsSelectedOptionsProvider.notifier)
                          .state = [];

                      ref
                          .read(allTracksAlbumsSelectedOptionsProvider.notifier)
                          .state = [];
                    },
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    text: "Imports",
                    type: AppButtonType.primary,
                    onPressed: () {
                      ImportTracksModal.showModal(context);
                    },
                  ),
                  if (size == AppScreenTypeLayout.desktop)
                    const SizedBox(width: 24),
                  if (size == AppScreenTypeLayout.desktop)
                    Expanded(
                      child: searchField,
                    ),
                ],
              ),
              if (showFilterPanel.value)
                MaxContainer(
                  maxWidth: maxWidth,
                  padding: EdgeInsets.zero,
                  child: const AllTrackFilterPanel(),
                ),
            ],
          ),
        );
      },
    );
  }
}
