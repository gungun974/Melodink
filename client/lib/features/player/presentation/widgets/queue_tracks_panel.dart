import 'package:flutter/material.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_page.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/mobile_track.dart';
import 'package:sliver_tools/sliver_tools.dart';

enum QueueTracksPanelType {
  start,
  middle,
  end,
}

class QueueTracksPanel extends StatelessWidget {
  final String name;
  final QueueTracksPanelType type;
  final AppScreenTypeLayout size;

  final List<QueueTrack> tracks;
  final void Function(MinimalTrack track, int index) playCallback;

  final bool useQueueTrack;
  final int trackNumberOffset;

  final String dragAndDropKeyPrefix;

  const QueueTracksPanel({
    super.key,
    required this.name,
    required this.type,
    required this.size,
    required this.tracks,
    required this.playCallback,
    this.useQueueTrack = true,
    this.trackNumberOffset = 0,
    this.dragAndDropKeyPrefix = "",
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
    final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;
    final separator = size == AppScreenTypeLayout.desktop ? 16.0 : 10.0;

    return MultiSliver(
      children: [
        SliverContainer(
          maxWidth: maxWidth,
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: type == QueueTracksPanelType.start ? 16.0 : 0,
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
              padding: EdgeInsets.only(
                top: 8,
                left: size == AppScreenTypeLayout.desktop ? 20 : 12,
                right: size == AppScreenTypeLayout.desktop ? 20 : 12,
                bottom: size == AppScreenTypeLayout.desktop ? 4 : 8,
              ),
              child: Text(
                name,
                style: size == AppScreenTypeLayout.desktop
                    ? const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                        letterSpacing: 20 * 0.03,
                      )
                    : const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        letterSpacing: 16 * 0.03,
                      ),
              ),
            ),
          ),
        ),
        if (!useQueueTrack && size == AppScreenTypeLayout.desktop)
          SliverContainer(
            maxWidth: maxWidth,
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
            ),
            sliver: SliverToBoxAdapter(
              child: Container(
                color: const Color.fromRGBO(0, 0, 0, 0.03),
                child: const DesktopTrackHeader(
                  displayLike: false,
                ),
              ),
            ),
          ),
        SliverContainer(
          maxWidth: maxWidth,
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
          ),
          sliver: SliverToBoxAdapter(
            child: ReorderableItem(
              key: Key("Prev-$dragAndDropKeyPrefix"),
              childBuilder: (BuildContext context, ReorderableItemState state) {
                return Container(
                  color: Colors.transparent,
                  height: 0,
                );
              },
            ),
          ),
        ),
        SliverContainer(
          maxWidth: maxWidth,
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
          ),
          sliver: SliverFixedExtentList(
            itemExtent: 50,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                late final Widget child;

                if (useQueueTrack) {
                  if (size == AppScreenTypeLayout.mobile) {
                    child = MobileTrack(
                      track: tracks[index].track,
                      playCallback: (track) {
                        playCallback(track, index);
                      },
                      displayImage: false,
                      displayMoreActions: false,
                      displayReorderable: true,
                    );
                  } else {
                    child = DesktopTrack(
                      track: tracks[index].track,
                      trackNumber: trackNumberOffset + index + 1,
                      playCallback: (track) {
                        playCallback(track, index);
                      },
                      displayImage: false,
                      displayLike: false,
                      displayMoreActions: false,
                      displayReorderable: true,
                    );
                  }
                } else {
                  if (size == AppScreenTypeLayout.mobile) {
                    child = MobileTrack(
                      track: tracks[index].track,
                      playCallback: (track) {
                        playCallback(track, index);
                      },
                    );
                  } else {
                    child = DesktopTrack(
                      track: tracks[index].track,
                      trackNumber: trackNumberOffset + index + 1,
                      playCallback: (track) {
                        playCallback(track, index);
                      },
                      displayLike: false,
                    );
                  }
                }

                return ReorderableItem(
                  key: tracks[index].key,
                  childBuilder:
                      (BuildContext context, ReorderableItemState state) {
                    return Opacity(
                      opacity:
                          state == ReorderableItemState.placeholder ? 0.0 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: state == ReorderableItemState.normal
                              ? const Color.fromRGBO(0, 0, 0, 0.03)
                              : const Color.fromRGBO(0, 0, 0, 0.05),
                          borderRadius: index != tracks.length - 1
                              ? null
                              : const BorderRadius.vertical(
                                  bottom: Radius.circular(
                                    8,
                                  ),
                                ),
                        ),
                        child: child,
                      ),
                    );
                  },
                );
              },
              childCount: tracks.length,
            ),
          ),
        ),
        SliverContainer(
          maxWidth: maxWidth,
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
          ),
          sliver: SliverToBoxAdapter(
            child: ReorderableItem(
              key: Key("Next-$dragAndDropKeyPrefix"),
              childBuilder: (BuildContext context, ReorderableItemState state) {
                return Container(
                  color: Colors.transparent,
                  height: 0,
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: type == QueueTracksPanelType.end ? 0.0 : separator,
          ),
        ),
      ],
    );
  }
}
