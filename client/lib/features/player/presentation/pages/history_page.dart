import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/features/tracker/domain/providers/played_track_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPreviousTracks = ref.watch(lastHistoryTracksProvider);

    final previousTracks = asyncPreviousTracks.valueOrNull;

    if (previousTracks == null) {
      return const AppPageLoader();
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
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
            ),
            sliver: TrackList(
              tracks: previousTracks,
              size: AppScreenTypeLayout.desktop,
              showImage: false,
              showTrackIndex: false,
              modules: const [
                DesktopTrackModule.title,
                DesktopTrackModule.duration,
                DesktopTrackModule.moreActions,
              ],
              source: t.general.playingFromHistory,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),
        ],
      );
    });
  }
}
