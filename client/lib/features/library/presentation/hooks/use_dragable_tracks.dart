import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

(
  ValueNotifier<List<Track>>,
  ValueNotifier<List<ValueKey<int>>>,
  bool Function(Key item, Key newPosition),
  Null Function(Key draggedItem),
  CancellationToken,
) useDragableTracks(
  ValueNotifier<List<Track>> tracks,
  void Function(List<Track> newTracks) reoderDoneCallback, [
  List<Object?> keys = const <Object>[],
]) {
  final orderTracks = useState(tracks.value);
  final orderKeys = useState(
    tracks.value.indexed.map((e) => ValueKey(e.$1)).toList(),
  );

  useEffect(() {
    void update() {
      orderTracks.value = tracks.value;
      orderKeys.value =
          tracks.value.indexed.map((e) => ValueKey(e.$1)).toList();
    }

    tracks.addListener(update);

    return () {
      tracks.removeListener(update);
    };
  }, [tracks]);

  int indexOfKey(Key key) {
    return orderKeys.value.indexWhere((Key d) => d == key);
  }

  final reorderCallback = useCallback((Key item, Key newPosition) {
    if (item is! ValueKey<int>) {
      orderTracks.value = tracks.value;
      return false;
    }

    if (newPosition is! ValueKey<int>) {
      orderTracks.value = tracks.value;
      return false;
    }

    final draggingIndex = indexOfKey(item);
    final newPositionIndex = indexOfKey(newPosition);

    final newTracks = [...orderTracks.value];
    final newOrderKeys = [...orderKeys.value];

    newTracks.insert(
      newPositionIndex,
      newTracks.removeAt(draggingIndex),
    );

    newOrderKeys.insert(
      newPositionIndex,
      newOrderKeys.removeAt(draggingIndex),
    );

    orderTracks.value = newTracks;
    orderKeys.value = newOrderKeys;

    return true;
  }, [tracks]);

  final reorderDone = useCallback((Key draggedItem) {
    reoderDoneCallback(orderTracks.value);
  }, keys);

  final dragCancelToken = useMemoized(() => CancellationToken());

  return (
    orderTracks,
    orderKeys,
    reorderCallback,
    reorderDone,
    dragCancelToken,
  );
}
