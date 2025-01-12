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

  final List<DesktopTrackModule> modules;

  final bool showImage;

  final bool showTrackIndex;

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
    Set<int> selectedIndexes,
    VoidCallback unselect,
  )? multiCustomActionsBuilder;

  final String? source;

  final void Function(MinimalTrack track, int index)? playCallback;

  const TrackList({
    super.key,
    required this.tracks,
    required this.size,
    required this.modules,
    this.showImage = true,
    this.showTrackIndex = true,
    this.singleCustomActionsBuilder,
    this.multiCustomActionsBuilder,
    this.scrollController,
    this.autoScrollToCurrentTrack = false,
    this.scrollToTrackIdOnMounted,
    this.source,
    this.playCallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final startSelect = useState<int?>(null);
    final endSelect = useState<int?>(null);

    final startElement = useState<int>(-1);

    final selectedElements = useState(<int>{});

    selectMultiple(int index) {
      if (!selectedElements.value.contains(index)) {
        selectedElements.value = {...selectedElements.value, index};
      } else {
        selectedElements.value = selectedElements.value
            .where(
              (el) => el != index,
            )
            .toSet();
      }

      if (selectedElements.value.length == 1) {
        startElement.value = index;
      }
    }

    selectMultipleRange(int index) {
      selectedElements.value = {...selectedElements.value, index};

      if (selectedElements.value.length == 1) {
        startElement.value = index;
      }

      final startIndex = startElement.value;
      final endIndex = index;

      if (startIndex == -1 || endIndex == -1) {
        return;
      }

      final minIndex = min(startIndex, endIndex);
      final maxIndex = max(endIndex, startIndex);

      final newElements = <int>{};

      for (var i = minIndex; i <= maxIndex; i++) {
        newElements.add(i);
      }

      selectedElements.value = newElements;
    }

    final listController = useListController();

    ref.listen(currentTrackStreamProvider, (asyncPrevTrack, asyncCurrentTrack) {
      if (!autoScrollToCurrentTrack) {
        return;
      }

      final currentTrack = asyncCurrentTrack.valueOrNull;

      final prevTrack = asyncPrevTrack?.valueOrNull;

      if (currentTrack == null) {
        return;
      }

      if (prevTrack?.id == currentTrack.id) {
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

      final visibleRange = listController.visibleRange;

      if (visibleRange != null) {
        final (startView, endView) = visibleRange;

        if (startView + 3 >= currentTrackIndex &&
            currentTrackIndex >= startView) {
          listController.animateToItem(
            index: currentTrackIndex,
            scrollController: scrollController!,
            alignment: 0.1,
            curve: (_) => Curves.easeOutQuad,
            duration: (_) => const Duration(milliseconds: 400),
          );

          return;
        }

        if (endView - 3 <= currentTrackIndex && currentTrackIndex <= endView) {
          listController.animateToItem(
            index: currentTrackIndex,
            scrollController: scrollController!,
            alignment: 0.9,
            curve: (_) => Curves.easeOutQuad,
            duration: (_) => const Duration(milliseconds: 400),
          );

          return;
        }

        if (startView <= currentTrackIndex && currentTrackIndex <= endView) {
          return;
        }
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

          final selected = selectedElements.value.contains(index);

          final List<MinimalTrack> selectedTracks = tracks.indexed
              .where(
                (entry) => selectedElements.value.contains(
                  entry.$1,
                ),
              )
              .map(
                (entry) => entry.$2,
              )
              .toList();

          selectCallback(track) {
            if (HardwareKeyboard.instance.isShiftPressed) {
              selectMultipleRange(index);
              return;
            }

            if (HardwareKeyboard.instance.isControlPressed) {
              selectMultiple(index);
              return;
            }

            selectedElements.value = {index};
            startElement.value = index;
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
              selectedElements.value.isNotEmpty) {
            localMultiCustomActionsBuilder = (context, menuController, tracks) {
              return multiCustomActionsBuilder!(
                context,
                menuController,
                tracks,
                selectedElements.value,
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
                if (playCallback != null) {
                  playCallback?.call(track, index);
                  return;
                }
                await audioController.loadTracks(
                  tracks,
                  startAt: index,
                  source: source,
                );
              },
              selected: selected,
              selectedTop: !selectedElements.value.contains(index - 1),
              selectedBottom: !selectedElements.value.contains(index + 1),
              selectedTracks: selectedTracks.length == 1 ? [] : selectedTracks,
              selectCallback: selectCallback,
              singleCustomActionsBuilder: localSingleCustomActionsBuilder,
              multiCustomActionsBuilder: localMultiCustomActionsBuilder,
            );
          } else {
            child = DesktopTrack(
              track: tracks[index],
              trackNumber:
                  showTrackIndex ? tracks[index].trackNumber : index + 1,
              playCallback: (track) async {
                if (playCallback != null) {
                  playCallback?.call(track, index);
                  return;
                }
                await audioController.loadTracks(
                  tracks,
                  startAt: index,
                  source: source,
                );
              },
              modules: modules,
              showImage: showImage,
              selected: selected,
              selectedTracks: selectedTracks.length == 1 ? [] : selectedTracks,
              selectCallback: selectCallback,
              selectedTop: !selectedElements.value.contains(index - 1),
              selectedBottom: !selectedElements.value.contains(index + 1),
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
