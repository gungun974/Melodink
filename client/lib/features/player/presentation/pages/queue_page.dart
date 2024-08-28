import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_queue_controls.dart';
import 'package:melodink_client/features/player/presentation/widgets/queue_tracks_panel.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return AppScreenTypeLayoutBuilder(builder: (context, size) {
      return Stack(
        children: [
          const GradientBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: size == AppScreenTypeLayout.mobile
                ? AppBar(
                    leading: IconButton(
                      icon: SvgPicture.asset(
                        "assets/icons/arrow-down.svg",
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    title: const Text(
                      "Queue",
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: 20 * 0.03,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    centerTitle: true,
                    backgroundColor: const Color.fromRGBO(0, 0, 0, 0.08),
                    shadowColor: Colors.transparent,
                  )
                : null,
            body: StreamBuilder(
              stream: audioController.currentTrack.stream,
              builder: (context, snapshot) {
                final currentTrack = snapshot.data;
                if (currentTrack == null) {
                  return Container();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (size == AppScreenTypeLayout.desktop)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 1200 + 48),
                        padding: const EdgeInsets.only(left: 24.0, top: 24.0),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Queue",
                                style: TextStyle(
                                  fontSize: 48,
                                  letterSpacing: 48 * 0.03,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          //! Now playing
                          QueueTracksPanel(
                            name: 'Now playing',
                            type: QueueTracksPanelType.start,
                            size: size,
                            tracks: [audioController.previousTracks.value.last],
                            playCallback: (_, __) {},
                            useQueueTrack: false,
                          ),
                          //! Next in Queue
                          if (audioController.queueTracks.value.isNotEmpty)
                            QueueTracksPanel(
                              name: 'Next in Queue',
                              size: size,
                              type: QueueTracksPanelType.middle,
                              tracks: audioController.queueTracks.value,
                              playCallback: (_, index) {
                                audioController.skipToQueueItem(
                                  index +
                                      audioController
                                          .previousTracks.value.length,
                                );
                              },
                              trackNumberOffset: 1,
                            ),

                          //! Next
                          if (audioController.nextTracks.value.isNotEmpty)
                            QueueTracksPanel(
                              name: 'Next',
                              type: QueueTracksPanelType.end,
                              size: size,
                              tracks: audioController.nextTracks.value,
                              playCallback: (_, index) {
                                audioController.skipToQueueItem(
                                  index +
                                      audioController
                                          .previousTracks.value.length +
                                      audioController.queueTracks.value.length,
                                );
                              },
                              trackNumberOffset:
                                  audioController.queueTracks.value.length + 1,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppScreenTypeLayoutBuilders(
                      mobile: (_) => const PlayerQueueControls(),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
