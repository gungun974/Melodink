import 'package:flutter/material.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/multi_tracks_context_menu.dart';
import 'package:melodink_client/features/track/presentation/widgets/single_track_context_menu.dart';

class TrackContextMenu extends StatelessWidget {
  const TrackContextMenu({
    super.key,
    required this.track,
    required this.tracks,
    required this.singleMenuController,
    required this.multiMenuController,
    required this.child,
    this.singleCustomActionsBuilder,
    this.multiCustomActionsBuilder,
    this.showDefaultActions = true,
  });

  final MinimalTrack track;

  final List<MinimalTrack> tracks;

  final MenuController singleMenuController;
  final MenuController multiMenuController;

  final bool showDefaultActions;

  final Widget child;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    MinimalTrack track,
  )? singleCustomActionsBuilder;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    List<MinimalTrack> tracks,
  )? multiCustomActionsBuilder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (TapDownDetails details) {
        if (tracks.isNotEmpty) {
          multiMenuController.open(
            position: details.localPosition + const Offset(5, 5),
          );
          return;
        }
        singleMenuController.open(
          position: details.localPosition + const Offset(5, 5),
        );
      },
      child: MultiTracksContextMenu(
        tracks: tracks,
        menuController: multiMenuController,
        customActionsBuilder: multiCustomActionsBuilder,
        showDefaultActions: showDefaultActions,
        child: SingleTrackContextMenu(
          track: track,
          menuController: singleMenuController,
          customActionsBuilder: singleCustomActionsBuilder,
          showDefaultActions: showDefaultActions,
          child: child,
        ),
      ),
    );
  }
}
