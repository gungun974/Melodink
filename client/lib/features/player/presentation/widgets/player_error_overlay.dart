import 'dart:async';

import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';

class PlayerErrorOverlay extends HookConsumerWidget {
  final Widget child;

  const PlayerErrorOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return StreamBuilder(
      stream: audioController.playbackState.stream,
      builder: (context, snapshot) {
        if (audioController.playbackState.valueOrNull?.processingState !=
            AudioProcessingState.error) {
          return child;
        }

        return HookBuilder(builder: (context) {
          final childKey = useMemoized(() => GlobalKey());
          final childSize = useState<Size?>(null);

          useEffect(() {
            calculateSize(_) {
              final renderBox =
                  childKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                if (renderBox.size != childSize.value) {
                  childSize.value = renderBox.size;
                }
              }
            }

            WidgetsBinding.instance.addPostFrameCallback(calculateSize);

            final timer = Timer.periodic(
              const Duration(milliseconds: 10),
              calculateSize,
            );

            return timer.cancel;
          }, []);

          return Stack(
            children: [
              Opacity(
                opacity: 0.5,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.saturation,
                  ),
                  child: Container(
                    key: childKey,
                    child: child,
                  ),
                ),
              ),
              SizedBox(
                width: childSize.value?.width ?? 16,
                height: childSize.value?.height ?? 16,
                child: Center(
                  child: AdwaitaIcon(
                    AdwaitaIcons.warning,
                    size: childSize.value?.width != null
                        ? childSize.value!.width * 0.5
                        : 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
