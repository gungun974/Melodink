import 'dart:math';

import 'package:flutter/material.dart';

class AppPageLoader extends StatelessWidget {
  const AppPageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -0.2, end: 1.0),
      curve: Curves.ease,
      duration: const Duration(seconds: 1),
      builder: (BuildContext context, double opacity, Widget? child) {
        return Opacity(
          opacity: max(opacity, 0.0),
          child: Container(
            color: const Color.fromRGBO(0, 0, 0, 0.7),
            child: const Center(
              child: SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
