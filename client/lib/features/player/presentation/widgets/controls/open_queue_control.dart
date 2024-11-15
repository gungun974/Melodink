import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/provider.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';

class OpenQueueControl extends ConsumerWidget {
  final bool largeControlButton;

  const OpenQueueControl({
    super.key,
    this.largeControlButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUrl = ref.watch(appRouterCurrentUrl);

    return AppIconButton(
      padding: const EdgeInsets.all(8),
      icon: const AdwaitaIcon(
        AdwaitaIcons.music_queue,
      ),
      iconSize: largeControlButton ? 24.0 : 20.0,
      color: currentUrl == "/queue"
          ? Theme.of(context).colorScheme.primary
          : Colors.white,
      onPressed: () async {
        if (currentUrl == "/queue") {
          GoRouter.of(context).pop();
          return;
        }
        GoRouter.of(context).push("/queue");
      },
    );
  }
}
