import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onToggle,
  });

  final bool value;

  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return FlutterSwitch(
      width: 24.0 * 2,
      height: 24.0,
      toggleSize: 18,
      padding: 3.5,
      value: value,
      activeColor: const Color.fromRGBO(196, 126, 208, 1),
      onToggle: onToggle,
    );
  }
}
