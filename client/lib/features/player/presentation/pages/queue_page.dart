import 'dart:async';

import 'package:flutter/material.dart' hide ReorderableList;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/queue_tracks_panel.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class QueueTrack {
  final Track track;
  final Key key;

  QueueTrack({required this.track, required this.key});
}

class QueuePage extends StatefulHookWidget {
  const QueuePage({
    super.key,
    required this.audioController,
    required this.size,
  });

  final AudioController audioController;

  final AppScreenTypeLayout size;

  @override
  State<QueuePage> createState() => _QueueReordableManagerState();
}

class _QueueReordableManagerState extends State<QueuePage> {
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

    if (newPosition is ValueKey<String> && newPosition.value == "Next-queue") {
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

    if (queueTracks.isEmpty &&
        newPosition is ValueKey<String> &&
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
    final scrollController = useScrollController();

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

    return ReorderableList(
      onReorder: _reorderCallback,
      onReorderDone: _reorderDone,
      cancellationToken: dragCancelToken,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          //! Now playing
          QueueTracksPanel(
            name: t.general.nowPlaying,
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
              name: t.general.nextInQueue,
              size: widget.size,
              type: QueueTracksPanelType.middle,
              tracks: queueTracks,
              playCallback: (_, index) {
                widget.audioController.skipToQueueItem(
                  index + widget.audioController.previousTracks.value.length,
                );
              },
              clearQueueCallback: () {
                widget.audioController.clearQueue();
              },
              trackNumberOffset: 1,
              dragAndDropKeyPrefix: "queue",
            ),

          //! Next
          if (widget.audioController.nextTracks.value.isNotEmpty ||
              nextTracks.isNotEmpty)
            QueueTracksPanel(
              name: t.general.next,
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
