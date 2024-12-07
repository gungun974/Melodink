import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';

class AppModal extends StatelessWidget {
  final Widget body;

  final Widget? title;

  final List<Widget>? actions;

  final bool preventUserClose;

  const AppModal({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.preventUserClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black),
        const GradientBackground(),
        Material(
          color: Colors.transparent,
          child: Column(
            children: [
              AppBar(
                leading: preventUserClose
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const AdwaitaIcon(AdwaitaIcons.window_close),
                        onPressed: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(),
                      ),
                actions: actions,
                centerTitle: true,
                backgroundColor: const Color.fromRGBO(0, 0, 0, 0.08),
                shadowColor: Colors.transparent,
                title: title,
              ),
              Expanded(
                child: body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
