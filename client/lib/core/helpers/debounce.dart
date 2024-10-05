import 'dart:async';

class Debouncer {
  final int milliseconds;
  void Function()? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(void Function() action) {
    _timer?.cancel();

    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
