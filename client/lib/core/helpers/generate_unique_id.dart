int _counter = 0;

String generateUniqueID() {
  final int now = DateTime.now().microsecondsSinceEpoch;
  _counter = (_counter + 1) % 1000;
  return "$now-$_counter";
}
