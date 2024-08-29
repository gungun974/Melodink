import 'dart:async';

import 'package:flutter/material.dart' hide ReorderableList;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_queue_controls.dart';
import 'package:melodink_client/features/player/presentation/widgets/queue_tracks_panel.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

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
                      child: QueueReordableManager(
                        audioController: audioController,
                        size: size,
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

class QueueTrack {
  final MinimalTrack track;
  final Key key;

  QueueTrack({required this.track, required this.key});
}

class QueueReordableManager extends StatefulWidget {
  const QueueReordableManager({
    super.key,
    required this.audioController,
    required this.size,
  });

  final AudioController audioController;

  final AppScreenTypeLayout size;

  @override
  State<QueueReordableManager> createState() => _QueueReordableManagerState();
}

class _QueueReordableManagerState extends State<QueueReordableManager> {
  List<QueueTrack> queueTracks = [];
  List<QueueTrack> nextTracks = [];

  bool isDraging = false;

  final dragCancelToken = CancellationToken();

  syncRealCurrentTracks() {
    int keyCounter = 0;

    dragCancelToken.cancelDragging();

    setState(() {
      queueTracks = widget.audioController.queueTracks.value
          .map((track) => QueueTrack(track: track, key: ValueKey(++keyCounter)))
          .toList();
      nextTracks = widget.audioController.nextTracks.value
          .map((track) => QueueTrack(track: track, key: ValueKey(++keyCounter)))
          .toList();
    });
  }

  late final StreamSubscription updateStream;

  @override
  initState() {
    super.initState();

    syncRealCurrentTracks();

    updateStream = widget.audioController.currentTrack.listen((_) {
      syncRealCurrentTracks();
    });
  }

  @override
  dispose() {
    updateStream.cancel();
    super.dispose();
  }

  int _indexOfKey(Key key, List<QueueTrack> tracks) {
    return tracks.indexWhere((QueueTrack d) => d.key == key);
  }

  bool _reorderCallback(Key item, Key newPosition) {
    setState(() {
      isDraging = true;
    });

    final queueDraggingIndex = _indexOfKey(item, queueTracks);
    final nextDraggingIndex = _indexOfKey(item, nextTracks);

    final isItemFromQueue = queueDraggingIndex != -1;

    final draggedItem = isItemFromQueue
        ? queueTracks[queueDraggingIndex]
        : nextTracks[nextDraggingIndex];

    if (newPosition is ValueKey<String> && newPosition.value == "Prev-next") {
      setState(() {
        if (isItemFromQueue) {
          queueTracks.removeAt(queueDraggingIndex);
        } else {
          nextTracks.removeAt(nextDraggingIndex);
        }
        nextTracks.insert(0, draggedItem);
      });
      return false;
    }

    if (newPosition is ValueKey<String> &&
        newPosition.value.contains("queue")) {
      setState(() {
        if (isItemFromQueue) {
          queueTracks.removeAt(queueDraggingIndex);
        } else {
          nextTracks.removeAt(nextDraggingIndex);
        }
        queueTracks.add(draggedItem);
      });
      return false;
    }

    if (newPosition is ValueKey<String> &&
        newPosition.value.contains("playing")) {
      setState(() {
        if (isItemFromQueue) {
          queueTracks.removeAt(queueDraggingIndex);
        } else {
          nextTracks.removeAt(nextDraggingIndex);
        }
        queueTracks.add(draggedItem);
      });
      return false;
    }

    if (newPosition is ValueKey<String>) {
      return false;
    }

    final queueNewPositionIndex = _indexOfKey(newPosition, queueTracks);
    final nextNewPositionIndex = _indexOfKey(newPosition, nextTracks);

    final isNewPositionFromQueue = queueNewPositionIndex != -1;

    setState(() {
      if (isItemFromQueue) {
        queueTracks.removeAt(queueDraggingIndex);
      } else {
        nextTracks.removeAt(nextDraggingIndex);
      }
      if (isNewPositionFromQueue) {
        queueTracks.insert(queueNewPositionIndex, draggedItem);
      } else {
        nextTracks.insert(nextNewPositionIndex, draggedItem);
      }
    });
    return true;
  }

  void _reorderDone(Key item) {
    setState(() {
      isDraging = false;
    });

    Future(() async {
      await widget.audioController.setQueueAndNext(
        queueTracks.map((track) => track.track).toList(),
        nextTracks.map((track) => track.track).toList(),
      );

      syncRealCurrentTracks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableList(
      onReorder: _reorderCallback,
      onReorderDone: _reorderDone,
      cancellationToken: dragCancelToken,
      child: CustomScrollView(
        slivers: [
          //! Now playing
          QueueTracksPanel(
            name: 'Now playing',
            type: QueueTracksPanelType.start,
            size: widget.size,
            tracks: [
              QueueTrack(
                track: widget.audioController.previousTracks.value.last,
                key: const Key("playing"),
              ),
            ],
            playCallback: (_, __) {},
            useQueueTrack: false,
            dragAndDropKeyPrefix: "playing",
          ),
          //! Next in Queue
          if (widget.audioController.queueTracks.value.isNotEmpty ||
              queueTracks.isNotEmpty)
            QueueTracksPanel(
              name: 'Next in Queue',
              size: widget.size,
              type: QueueTracksPanelType.middle,
              tracks: queueTracks,
              playCallback: (_, index) {
                widget.audioController.skipToQueueItem(
                  index + widget.audioController.previousTracks.value.length,
                );
              },
              trackNumberOffset: 1,
              dragAndDropKeyPrefix: "queue",
            ),

          //! Next
          if (widget.audioController.nextTracks.value.isNotEmpty ||
              nextTracks.isNotEmpty)
            QueueTracksPanel(
              name: 'Next',
              type: QueueTracksPanelType.end,
              size: widget.size,
              tracks: nextTracks,
              playCallback: (_, index) {
                widget.audioController.skipToQueueItem(
                  index +
                      widget.audioController.previousTracks.value.length +
                      queueTracks.length,
                );
              },
              trackNumberOffset: queueTracks.length + 1,
              dragAndDropKeyPrefix: "next",
            ),
        ],
      ),
    );
  }
}
