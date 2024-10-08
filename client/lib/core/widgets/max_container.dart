import 'package:flutter/material.dart';

class MaxContainer extends StatelessWidget {
  final int? maxWidth;
  final int? maxHeight;
  final EdgeInsets padding;
  final Widget child;

  const MaxContainer({
    super.key,
    this.maxWidth,
    this.maxHeight,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.constrainWidth();
        final height = constraints.constrainHeight();

        final notNullMaxWidth = maxWidth ?? 0;
        final notNullMaxHeight = maxHeight ?? 0;

        final double horizontalPadding =
            width > notNullMaxWidth + (padding.horizontal)
                ? (width - notNullMaxWidth) / 2
                : padding.horizontal / 2;

        final double verticalPadding =
            height > notNullMaxHeight + (padding.vertical)
                ? (height - notNullMaxHeight) / 2
                : padding.vertical / 2;

        return Padding(
          padding: EdgeInsets.only(
            left: maxWidth == null ? padding.left : horizontalPadding,
            right: maxWidth == null ? padding.right : horizontalPadding,
            top: maxHeight == null ? padding.top : verticalPadding,
            bottom: maxHeight == null ? padding.bottom : verticalPadding,
          ),
          child: child,
        );
      },
    );
  }
}
