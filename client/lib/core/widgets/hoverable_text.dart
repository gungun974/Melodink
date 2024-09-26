import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HoverableText extends HookWidget {
  const HoverableText({
    super.key,
    required this.text,
    this.style,
    this.hoverStyle,
  });

  final String text;

  final TextStyle? style;

  final TextStyle? hoverStyle;

  @override
  Widget build(BuildContext context) {
    final isHover = useState(false);

    return MouseRegion(
      onEnter: (_) {
        isHover.value = true;
      },
      onExit: (_) {
        isHover.value = false;
      },
      child: Text(
        text,
        style: isHover.value && hoverStyle != null ? hoverStyle : style,
      ),
    );
  }
}
