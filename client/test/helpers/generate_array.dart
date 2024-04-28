List<T> generateArray<T>(T Function() generator, int length) {
  List<T> result = [];

  while (result.length < length) {
    result.add(generator());
  }

  return result;
}
