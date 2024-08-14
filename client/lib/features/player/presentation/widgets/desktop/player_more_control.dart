import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/routes.dart';

class PlayerMoreControls extends StatelessWidget {
  final String location;

  const PlayerMoreControls({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          padding: const EdgeInsets.only(),
          icon: AdwaitaIcon(
            AdwaitaIcons.music_queue,
            color: location == "/queue" || location == "/player/queue"
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
          ),
          iconSize: 20.0,
          color: Colors.white,
          onPressed: () {
            if (location == "/queue") {
              GoRouter.of(context).pop();
              while (GoRouter.of(context).location.startsWith("/player")) {
                GoRouter.of(context).pop();
              }
              return;
            }
            GoRouter.of(context).push("/queue");
          },
        ),
      ],
    );
  }
}
