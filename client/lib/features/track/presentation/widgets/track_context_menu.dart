import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
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
  });

  final MinimalTrack track;

  final List<MinimalTrack> tracks;

  final MenuController singleMenuController;
  final MenuController multiMenuController;

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
        child: SingleTrackContextMenu(
          track: track,
          menuController: singleMenuController,
          customActionsBuilder: singleCustomActionsBuilder,
          child: child,
        ),
      ),
    );
  }
}

class TrackContextMenuButton extends StatelessWidget {
  const TrackContextMenuButton({
    super.key,
    required this.trackContextMenuKey,
    required this.menuController,
    required this.padding,
  });

  final EdgeInsets padding;

  final GlobalKey<State<StatefulWidget>> trackContextMenuKey;
  final MenuController menuController;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent details) {
        if (menuController.isOpen) {
          menuController.close();
          return;
        }

        final trackContextMenuRenderBox =
            trackContextMenuKey.currentContext?.findRenderObject();

        if (trackContextMenuRenderBox is! RenderBox) {
          return;
        }

        final position = trackContextMenuRenderBox.localToGlobal(Offset.zero);

        final renderBox = context.findRenderObject();

        if (renderBox is! RenderBox) {
          return;
        }

        final Offset globalPosition = renderBox.localToGlobal(Offset.zero);

        menuController.open(
          position: globalPosition -
              position +
              Offset(
                0,
                renderBox.size.height * 7 / 8,
              ),
        );
      },
      child: Container(
        height: 50,
        color: Colors.transparent,
        child: AppIconButton(
          padding: padding,
          iconSize: 20,
          icon: const AdwaitaIcon(AdwaitaIcons.view_more_horizontal),
        ),
      ),
    );
  }
}
