import 'package:flutter/material.dart';

class SliverContainer extends StatelessWidget {
  final int maxWidth;
  final double padding;
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
        final double padding = width > maxWidth + this.padding
            ? (width - maxWidth) / 2
            : this.padding;

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: sliver,
        );
      },
    );
  }
}
