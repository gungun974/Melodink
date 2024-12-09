// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

enum AppButtonType {
  primary,
  secondary,
  neutral,
  danger,
}

class AppButton extends StatelessWidget {
  final String text;
  final AppButtonType type;

  final VoidCallback? onPressed;

  const AppButton({
    super.key,
    required this.text,
    required this.type,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          animationDuration: Duration.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          backgroundColor: switch (type) {
            AppButtonType.primary => const Color.fromRGBO(196, 126, 208, 1),
            AppButtonType.secondary => const Color.fromRGBO(152, 128, 209, 1),
            AppButtonType.neutral => const Color.fromRGBO(120, 144, 156, 0.55),
            AppButtonType.danger => const Color.fromRGBO(245, 88, 88, 1),
          },
          shadowColor: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 14 * 0.03,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
