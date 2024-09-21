import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class TrackContextMenu extends ConsumerWidget {
  const TrackContextMenu({
    super.key,
    required this.track,
    required this.menuController,
    required this.child,
  });

  final MinimalTrack track;

  final MenuController menuController;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return GestureDetector(
      onSecondaryTapDown: (TapDownDetails details) {
        menuController.open(
            position: details.localPosition + const Offset(5, 5));
      },
      child: MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const AdwaitaIcon(
              AdwaitaIcons.playlist,
              size: 20,
            ),
            child: const Text("Add to queue"),
            onPressed: () {
              audioController.addTrackToQueue(track);
            },
          ),
        ],
        controller: menuController,
        child: child,
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
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
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
