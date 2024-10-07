import 'package:flutter/material.dart';

class MaxContainer extends StatelessWidget {
  final int maxWidth;
  final EdgeInsets padding;
  final Widget child;

  const MaxContainer({
    super.key,
    required this.maxWidth,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.constrainWidth();
        final double padding = width > maxWidth + (this.padding.horizontal)
            ? (width - maxWidth) / 2
            : this.padding.horizontal / 2;

        return Padding(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: this.padding.top,
            bottom: this.padding.bottom,
          ),
          child: child,
        );
      },
    );
  }
}
