import 'package:flutter/material.dart';

Duration pageTransitonDuration = const Duration(milliseconds: 450);

Widget slideUpTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: animation.drive(
      Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInQuad)),
    ),
    child: child,
  );
}
