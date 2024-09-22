import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/mobile_track.dart';

class TrackList extends HookConsumerWidget {
  final List<MinimalTrack> tracks;

  final AppScreenTypeLayout size;

  final bool displayImage;
  final bool displayAlbum;

  final bool displayTrackIndex;

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
    this.displayImage = true,
    this.displayAlbum = true,
    this.displayTrackIndex = true,
    this.singleCustomActionsBuilder,
    this.multiCustomActionsBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final startSelect = useState<int?>(null);
    final endSelect = useState<int?>(null);

    return SliverList(
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
              displayImage: displayImage,
              displayAlbum: displayAlbum,
              selected: selected,
              selectedTracks: selectedTracks,
              selectCallback: selectCallback,
              singleCustomActionsBuilder: localSingleCustomActionsBuilder,
              multiCustomActionsBuilder: localMultiCustomActionsBuilder,
            );
          }

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: size == AppScreenTypeLayout.desktop ? 0 : 12,
            ),
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            child: child,
          );
        },
        childCount: tracks.length,
      ),
    );
  }
}
