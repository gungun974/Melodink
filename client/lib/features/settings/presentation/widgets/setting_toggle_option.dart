import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_switch.dart';

class SettingToggleOption extends StatelessWidget {
  const SettingToggleOption({
    super.key,
    required this.text,
    required this.value,
    required this.onToggle,
  });

  final String text;

  final bool value;

  final ValueChanged<bool> onToggle;

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
        AppSwitch(value: value, onToggle: onToggle),
      ],
    );
  }
}
