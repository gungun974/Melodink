import 'package:flutter/material.dart';

class SettingButtonOption extends StatelessWidget {
  const SettingButtonOption({
    super.key,
    required this.text,
    required this.action,
    required this.onPressed,
    this.isDanger = false,
  });

  final String text;

  final String action;

  final VoidCallback? onPressed;

  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16,
            letterSpacing: 16 * 0.04,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onPressed,
          style: const ButtonStyle(
            alignment: Alignment.centerRight,
          ),
          child: Text(
            action,
            style: TextStyle(
              color: isDanger ? const Color.fromRGBO(245, 88, 88, 1) : null,
            ),
          ),
        ),
      ],
    );
  }
}
