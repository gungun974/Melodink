String splitIdToPath(int id) {
  final s = id.toString().padLeft(6, '0');

  final n = s.length;

  final part1 = s.substring(0, n - 4);
  final part2 = s.substring(n - 4, n - 2);
  final part3 = s.substring(n - 2);

  return [part1, part2, part3].join("/");
}
