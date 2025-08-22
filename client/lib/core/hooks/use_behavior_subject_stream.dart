import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

AsyncSnapshot<T> useBehaviorSubjectStream<T>(
  BehaviorSubject<T> behaviorSubject,
) {
  return useStream(
    behaviorSubject.stream,
    initialData: behaviorSubject.valueOrNull,
  );
}
