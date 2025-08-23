import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:provider/provider.dart';

class OpenQueueControl extends StatelessWidget {
  final bool largeControlButton;

  const OpenQueueControl({super.key, this.largeControlButton = false});

  @override
  Widget build(BuildContext context) {
    final currentUrl = context.select<AppRouter, String>(
      (router) => router.currentPath(),
    );

    return AppIconButton(
      padding: const EdgeInsets.all(8),
      icon: const AdwaitaIcon(AdwaitaIcons.music_queue),
      iconSize: largeControlButton ? 24.0 : 20.0,
      color: currentUrl == "/queue"
          ? Theme.of(context).colorScheme.primary
          : Colors.white,
      onPressed: () async {
        if (currentUrl == "/queue") {
          context.read<AppRouter>().pop();
          return;
        }
        context.read<AppRouter>().push("/queue");
      },
    );
  }
}
