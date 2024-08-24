import 'package:flutter/material.dart';

class SliverContainer extends StatelessWidget {
  final int maxWidth;
  final EdgeInsets padding;
  final Widget sliver;

  const SliverContainer({
    super.key,
    required this.maxWidth,
    required this.padding,
    required this.sliver,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final double padding = width > maxWidth + (this.padding.horizontal)
            ? (width - maxWidth) / 2
            : this.padding.horizontal / 2;

        return SliverPadding(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: this.padding.top,
            bottom: this.padding.bottom,
          ),
          sliver: sliver,
        );
      },
    );
  }
}
