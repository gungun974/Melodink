// ignore_for_file: avoid_print

void Function() mesureTime(String name) {
  final now = DateTime.now();

  print("$name Start $now");

  return () {
    final end = DateTime.now();
    print("$name End $end - ${end.difference(now).inMilliseconds}ms");
  };
}
