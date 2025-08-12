import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/app_toggle_buttons.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/player/presentation/pages/history_page.dart';
import 'package:melodink_client/features/player/presentation/pages/queue_page.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_queue_controls.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class QueueAndHistoryPage extends HookConsumerWidget {
  const QueueAndHistoryPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    final currentPlayerBarPosition =
        ref.watch(currentPlayerBarPositionProvider);

    final currentTrack = ref.watch(currentTrackStreamProvider).valueOrNull;

    final isInQueuePage = useState(currentTrack != null);

    return AppScreenTypeLayoutBuilder(builder: (context, size) {
      return Stack(
        children: [
          const GradientBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: size == AppScreenTypeLayout.mobile ||
                    currentPlayerBarPosition == AppSettingPlayerBarPosition.side
                ? AppBar(
                    leading: IconButton(
                      icon: SvgPicture.asset(
                        "assets/icons/arrow-down.svg",
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    title: Text(
                      isInQueuePage.value ? t.general.queue : t.general.history,
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 20 * 0.03,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    centerTitle: true,
                    backgroundColor: const Color.fromRGBO(0, 0, 0, 0.08),
                    shadowColor: Colors.transparent,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: IconButton(
                          icon: isInQueuePage.value
                              ? const AdwaitaIcon(
                                  AdwaitaIcons.clock,
                                  size: 24,
                                  color: Colors.white,
                                )
                              : SvgPicture.asset(
                                  "assets/icons/history-undo-symbolic.svg",
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                          onPressed: () =>
                              isInQueuePage.value = !isInQueuePage.value,
                        ),
                      ),
                    ],
                  )
                : null,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (size == AppScreenTypeLayout.desktop &&
                    currentPlayerBarPosition !=
                        AppSettingPlayerBarPosition.side)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 1200 + 48),
                    padding: const EdgeInsets.only(
                        left: 24.0, right: 24.0, top: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isInQueuePage.value
                                ? t.general.queue
                                : t.general.history,
                            style: const TextStyle(
                              fontSize: 48,
                              letterSpacing: 48 * 0.03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        AppToggleButtons(
                          options: [
                            AppToggleButtonsOption(
                              text: t.general.queue,
                              icon: AdwaitaIcons.clock,
                            ),
                            AppToggleButtonsOption(
                              text: t.general.history,
                              icon: "assets/icons/history-undo-symbolic.svg",
                            ),
                          ],
                          isSelected: [
                            isInQueuePage.value,
                            !isInQueuePage.value
                          ],
                          onPressed: (index) {
                            if (index == 0) {
                              isInQueuePage.value = true;
                              return;
                            }
                            isInQueuePage.value = false;
                          },
                        ),
                      ],
                    ),
                  ),
                if (isInQueuePage.value)
                  Expanded(
                    child: Builder(builder: (context) {
                      if (currentTrack == null) {
                        return Center(
                          child: Text(
                            t.general.queueIsEmpty,
                            style: const TextStyle(
                              fontSize: 24,
                              letterSpacing: 24 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      return QueuePage(
                        audioController: audioController,
                        size: size,
                      );
                    }),
                  ),
                if (!isInQueuePage.value)
                  const Expanded(
                    child: HistoryPage(),
                  ),
                const SizedBox(height: 12),
                AppScreenTypeLayoutBuilders(
                  mobile: (_) => const PlayerQueueControls(),
                )
              ],
            ),
          ),
        ],
      );
    });
  }
}
