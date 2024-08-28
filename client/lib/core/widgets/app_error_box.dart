// ignore_for_file: prefer_const_constructors

import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';

class AppErrorBox extends StatelessWidget {
  final String? title;
  final String message;

  const AppErrorBox({
    super.key,
    this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF272727),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AdwaitaIcon(
              size: 32,
              AdwaitaIcons.dialog_warning,
              color: Colors.redAccent,
            ),
            SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? "Error",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: 15 * 0.03,
                    color: const Color(0xFFE84E4A),
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    letterSpacing: 13 * 0.03,
                    color: Colors.red[300],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
