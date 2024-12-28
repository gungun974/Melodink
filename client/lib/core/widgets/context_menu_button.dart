import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';

class ContextMenuButton extends StatelessWidget {
  const ContextMenuButton({
    super.key,
    required this.contextMenuKey,
    required this.menuController,
    required this.padding,
    this.direction = Axis.horizontal,
  });

  final EdgeInsets padding;

  final GlobalKey<State<StatefulWidget>> contextMenuKey;
  final MenuController menuController;

  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent details) {
        if (menuController.isOpen) {
          menuController.close();
          return;
        }

        final trackContextMenuRenderBox =
            contextMenuKey.currentContext?.findRenderObject();

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
          icon: direction == Axis.horizontal
              ? const AdwaitaIcon(AdwaitaIcons.view_more_horizontal)
              : const AdwaitaIcon(AdwaitaIcons.view_more),
        ),
      ),
    );
  }
}
