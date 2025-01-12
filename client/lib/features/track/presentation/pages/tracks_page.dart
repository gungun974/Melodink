import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/form/app_search_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/all_track_filter_panel.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class TracksPage extends HookConsumerWidget {
  const TracksPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final tracks = ref.watch(allSortedTracksProvider).valueOrNull;
    final searchTracks = ref.watch(allFilteredAlbumsTracksProvider).valueOrNull;

    final isAutoScrollViewToCurrentTrackEnabled = ref.watch(
      isAutoScrollViewToCurrentTrackEnabledProvider,
    );

    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

    if (searchTracks == null || tracks == null) {
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
                  key: scrollViewKey,
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
                      sliver: StickyDesktopTrackHeader(
                        modules: [
                          DesktopTrackModule.title,
                          DesktopTrackModule.album,
                          DesktopTrackModule.lastPlayed,
                          DesktopTrackModule.playedCount,
                          DesktopTrackModule.dateAdded,
                          DesktopTrackModule.quality,
                          DesktopTrackModule.duration,
                          DesktopTrackModule.score,
                          DesktopTrackModule.moreActions,
                        ],
                        scrollController: scrollController,
                        scrollViewKey: scrollViewKey,
                      ),
                    ),
                    SliverContainer(
                      maxWidth: maxWidth,
                      padding: EdgeInsets.only(
                        left: padding,
                        right: padding,
                      ),
                      sliver: TrackList(
                        tracks: searchTracks,
                        size: size,
                        modules: const [
                          DesktopTrackModule.title,
                          DesktopTrackModule.album,
                          DesktopTrackModule.lastPlayed,
                          DesktopTrackModule.playedCount,
                          DesktopTrackModule.dateAdded,
                          DesktopTrackModule.quality,
                          DesktopTrackModule.duration,
                          DesktopTrackModule.score,
                          DesktopTrackModule.moreActions,
                        ],
                        showImage: true,
                        scrollController: scrollController,
                        autoScrollToCurrentTrack:
                            isAutoScrollViewToCurrentTrackEnabled,
                        playCallback: (track, _) async {
                          final index = tracks.indexWhere(
                            (trackd) => trackd.id == track.id,
                          );

                          if (index < 0) {
                            return;
                          }

                          await audioController.loadTracks(
                            tracks,
                            startAt: index,
                            source: t.general.playingFromAllTracks,
                          );
                        },
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
        final searchField = AppSearchFormField(
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
                    text: t.general.filter,
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
                    text: t.actions.viewAll,
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
