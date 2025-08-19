import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class EventBus {
  final StreamController _streamController;

  EventBus() : _streamController = StreamController.broadcast();

  Stream<T> on<T extends EventBusEvent>() {
    if (T == dynamic) {
      return _streamController.stream as Stream<T>;
    } else {
      return _streamController.stream.where((event) => event is T).cast<T>();
    }
  }

  void fire(EventBusEvent event) {
    _streamController.add(event);
  }
}

abstract class EventBusEvent {}

final eventBusProvider = Provider((ref) => EventBus());
