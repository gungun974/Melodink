import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/hooks/use_list_controller.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/mobile_track.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class TrackList extends HookConsumerWidget {
  final List<MinimalTrack> tracks;

  final AppScreenTypeLayout size;

  final bool displayDateAdded;

  final bool displayImage;
  final bool displayAlbum;
  final bool displayLike;

  final bool displayTrackIndex;

  final bool displayLastPlayed;
  final bool displayPlayedCount;
  final bool displayQuality;

  final ScrollController? scrollController;
  final bool autoScrollToCurrentTrack;
  final int? scrollToTrackIdOnMounted;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    MinimalTrack track,
    int index,
    VoidCallback unselect,
  )? singleCustomActionsBuilder;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    List<MinimalTrack> tracks,
    int startIndex,
    int endIndex,
    VoidCallback unselect,
  )? multiCustomActionsBuilder;

  const TrackList({
    super.key,
    required this.tracks,
    required this.size,
    this.displayDateAdded = false,
    this.displayImage = true,
    this.displayAlbum = true,
    this.displayLike = true,
    this.displayTrackIndex = true,
    this.displayLastPlayed = false,
    this.displayPlayedCount = false,
    this.displayQuality = false,
    this.singleCustomActionsBuilder,
    this.multiCustomActionsBuilder,
    this.scrollController,
    this.autoScrollToCurrentTrack = false,
    this.scrollToTrackIdOnMounted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final startSelect = useState<int?>(null);
    final endSelect = useState<int?>(null);

    final listController = useListController();

    ref.listen(currentTrackStreamProvider, (_, asyncCurrentTrack) {
      if (!autoScrollToCurrentTrack) {
        return;
      }

      final currentTrack = asyncCurrentTrack.valueOrNull;

      if (currentTrack == null) {
        return;
      }

      if (scrollController == null) {
        return;
      }

      final currentTrackIndex =
          tracks.indexWhere((track) => track.id == currentTrack.id);

      if (currentTrackIndex == -1) {
        return;
      }

      listController.jumpToItem(
        index: currentTrackIndex,
        scrollController: scrollController!,
        alignment: 0.4,
      );
    });

    useEffect(() {
      if (scrollToTrackIdOnMounted == null) return null;

      if (scrollController == null) return null;

      final currentTrackIndex =
          tracks.indexWhere((track) => track.id == scrollToTrackIdOnMounted);

      if (currentTrackIndex == -1) return null;

      Future.delayed(const Duration(milliseconds: 1)).then(
        (_) {
          listController.jumpToItem(
            index: currentTrackIndex,
            scrollController: scrollController!,
            alignment: 0.4,
          );
        },
      );

      return null;
    }, []);

    return SuperSliverList(
      extentEstimation: (_, __) => 50,
      listController: scrollController != null ? listController : null,
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          late final Widget child;

          final selected = startSelect.value == index ||
              (startSelect.value != null &&
                  endSelect.value != null &&
                  index >= min(startSelect.value!, endSelect.value!) &&
                  index <= max(startSelect.value!, endSelect.value!));

          late final List<MinimalTrack> selectedTracks;

          if (selected &&
              startSelect.value != null &&
              endSelect.value != null) {
            selectedTracks = tracks.sublist(
                min(startSelect.value!, endSelect.value!),
                max(startSelect.value!, endSelect.value!) + 1);
          } else {
            selectedTracks = const [];
          }

          selectCallback(track) {
            if (HardwareKeyboard.instance.isShiftPressed) {
              startSelect.value ??= 0;

              if (startSelect.value == index) {
                endSelect.value = null;
                return;
              }
              endSelect.value = index;
              return;
            }

            startSelect.value = index;
            endSelect.value = null;
          }

          List<Widget> Function(
              BuildContext context,
              MenuController menuController,
              MinimalTrack track)? localSingleCustomActionsBuilder;

          if (singleCustomActionsBuilder != null) {
            localSingleCustomActionsBuilder = (context, menuController, track) {
              return singleCustomActionsBuilder!(
                context,
                menuController,
                track,
                index,
                () {
                  startSelect.value = null;
                  endSelect.value = null;
                },
              );
            };
          }

          List<Widget> Function(
              BuildContext context,
              MenuController menuController,
              List<MinimalTrack> tracks)? localMultiCustomActionsBuilder;

          if (multiCustomActionsBuilder != null &&
              startSelect.value != null &&
              endSelect.value != null) {
            localMultiCustomActionsBuilder = (context, menuController, tracks) {
              return multiCustomActionsBuilder!(
                context,
                menuController,
                tracks,
                min(startSelect.value!, endSelect.value!),
                max(startSelect.value!, endSelect.value!),
                () {
                  startSelect.value = null;
                  endSelect.value = null;
                },
              );
            };
          }

          if (size == AppScreenTypeLayout.mobile) {
            child = MobileTrack(
              track: tracks[index],
              playCallback: (track) async {
                await audioController.loadTracks(
                  tracks,
                  startAt: index,
                );
              },
              selected: selected,
              selectedTracks: selectedTracks,
              selectCallback: selectCallback,
              singleCustomActionsBuilder: localSingleCustomActionsBuilder,
              multiCustomActionsBuilder: localMultiCustomActionsBuilder,
            );
          } else {
            child = DesktopTrack(
              track: tracks[index],
              trackNumber:
                  displayTrackIndex ? tracks[index].trackNumber : index + 1,
              playCallback: (track) async {
                await audioController.loadTracks(
                  tracks,
                  startAt: index,
                );
              },
              displayDateAdded: displayDateAdded,
              displayImage: displayImage,
              displayAlbum: displayAlbum,
              displayLike: displayLike,
              displayLastPlayed: displayLastPlayed,
              displayPlayedCount: displayPlayedCount,
              displayQuality: displayQuality,
              selected: selected,
              selectedTracks: selectedTracks,
              selectCallback: selectCallback,
              singleCustomActionsBuilder: localSingleCustomActionsBuilder,
              multiCustomActionsBuilder: localMultiCustomActionsBuilder,
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.03),
              borderRadius: BorderRadius.vertical(
                top: size == AppScreenTypeLayout.mobile && index == 0
                    ? const Radius.circular(8)
                    : Radius.zero,
                bottom: index == tracks.length - 1
                    ? const Radius.circular(8)
                    : Radius.zero,
              ),
            ),
            child: child,
          );
        },
        childCount: tracks.length,
      ),
    );
  }
}
