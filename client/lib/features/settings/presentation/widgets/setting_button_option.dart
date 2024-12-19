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
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 15,
              letterSpacing: 15 * 0.04,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onPressed,
          style: const ButtonStyle(
            alignment: Alignment.centerRight,
            visualDensity: VisualDensity.standard,
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
