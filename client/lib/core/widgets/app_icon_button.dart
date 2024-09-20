import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.padding,
    required this.iconSize,
    this.onPressed,
    this.color,
  });

  final Widget icon;

  final EdgeInsets padding;

  final double iconSize;

  final VoidCallback? onPressed;

  final Color? color;

  EdgeInsets subtractEdgeInsets(EdgeInsets a, EdgeInsets b) {
    return EdgeInsets.only(
      left: (a.left - b.left).clamp(0.0, double.infinity),
      top: (a.top - b.top).clamp(0.0, double.infinity),
      right: (a.right - b.right).clamp(0.0, double.infinity),
      bottom: (a.bottom - b.bottom).clamp(0.0, double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = SizedBox(
      width: iconSize,
      height: iconSize,
      child: icon,
    );

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        color: Colors.transparent,
        padding: subtractEdgeInsets(
          padding,
          const EdgeInsets.all(
            4,
          ),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.only(
              left: padding.left.clamp(0.0, 4.0),
              top: padding.top.clamp(0.0, 4.0),
              right: padding.right.clamp(0.0, 4.0),
              bottom: padding.bottom.clamp(0.0, 4.0),
            ),
            child: color != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                        color ?? Colors.white, BlendMode.srcIn),
                    child: iconWidget,
                  )
                : iconWidget,
          ),
        ),
      ),
    );
  }
}
