import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';

class AppModal extends StatelessWidget {
  final Widget body;

  final Widget? title;

  const AppModal({
    super.key,
    required this.body,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black),
        const GradientBackground(),
        Scaffold(
          primary: false,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: 0,
          ),
          body: Column(
            children: [
              AppBar(
                leading: IconButton(
                  icon: const AdwaitaIcon(AdwaitaIcons.window_close),
                  onPressed: () => Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(),
                ),
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
