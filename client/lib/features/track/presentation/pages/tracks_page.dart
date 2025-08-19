import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    hide ChangeNotifierProvider, Consumer, Provider;
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/form/app_search_form_field.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/presentation/view_models/tracks_view_model.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class TracksPage extends HookConsumerWidget {
  const TracksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAutoScrollViewToCurrentTrackEnabled = ref.watch(
      isAutoScrollViewToCurrentTrackEnabledProvider,
    );

    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

    return ChangeNotifierProvider(
      create: (_) => TracksViewModel(
        eventBus: ref.read(eventBusProvider),
        audioController: ref.read(audioControllerProvider),
        trackRepository: ref.read(trackRepositoryProvider),
      )..loadTracks(),
      child: Stack(
        children: [
          AppNavigationHeader(
            title: AppScreenTypeLayoutBuilders(
              mobile: (_) => const Text("Tracks"),
            ),
            child: AppScreenTypeLayoutBuilder(
              builder: (context, size) {
                final maxWidth = size == AppScreenTypeLayout.desktop
                    ? 1200
                    : 512;
                final padding = size == AppScreenTypeLayout.desktop
                    ? 24.0
                    : 16.0;

                return Column(
                  children: [
                    if (size == AppScreenTypeLayout.desktop)
                      TracksPageSearchHeader(padding: padding),
                    Expanded(
                      child: CustomScrollView(
                        key: scrollViewKey,
                        controller: scrollController,
                        slivers: [
                          if (size == AppScreenTypeLayout.mobile)
                            SliverToBoxAdapter(
                              child: TracksPageSearchHeader(padding: padding),
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
                            sliver: Consumer<TracksViewModel>(
                              builder: (context, viewModel, _) {
                                return TrackList(
                                  tracks: viewModel.searchTracks,
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
                                  playCallback: (track, _) =>
                                      viewModel.playTrack(track),
                                );
                              },
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TracksPageSearchHeader extends StatelessWidget {
  const TracksPageSearchHeader({super.key, required this.padding});

  final double padding;

  @override
  Widget build(BuildContext context) {
    return AppScreenTypeLayoutBuilder(
      builder: (context, size) {
        final searchField = AppSearchFormField(
          controller: context.read<TracksViewModel>().searchTextController,
          onChanged: (_) => context.read<TracksViewModel>().updateSearch(),
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
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
                    text: t.actions.viewAll,
                    type: AppButtonType.primary,
                    onPressed: () =>
                        context.read<TracksViewModel>().clearSearch(),
                  ),
                  if (size == AppScreenTypeLayout.desktop)
                    const SizedBox(width: 24),
                  if (size == AppScreenTypeLayout.desktop)
                    Expanded(child: searchField),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
