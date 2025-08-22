import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/player/presentation/viewmodels/history_viewmodel.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class HistoryPage extends riverpod.HookConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final scrollController = useScrollController();

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

    return ChangeNotifierProvider(
      create: (_) => HistoryViewModel(
        manager: ref.read(playerTrackerManagerProvider),
        playedTrackRepository: ref.read(playedTrackRepositoryProvider),
      )..fetchLastHistoryTracks(),
      child: AppScreenTypeLayoutBuilder(
        builder: (context, size) {
          final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
          final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 16.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: size == AppScreenTypeLayout.desktop
                        ? const DesktopTrackHeader(
                            modules: [
                              DesktopTrackModule.title,
                              DesktopTrackModule.duration,
                              DesktopTrackModule.moreActions,
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              SliverContainer(
                maxWidth: maxWidth,
                padding: EdgeInsets.only(left: padding, right: padding),
                sliver: Consumer<HistoryViewModel>(
                  builder: (context, viewModel, _) {
                    return TrackList(
                      tracks: viewModel.previousTracks,
                      size: AppScreenTypeLayout.desktop,
                      showImage: false,
                      showTrackIndex: false,
                      modules: const [
                        DesktopTrackModule.title,
                        DesktopTrackModule.duration,
                        DesktopTrackModule.moreActions,
                      ],
                      source: t.general.playingFromHistory,
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          );
        },
      ),
    );
  }
}
