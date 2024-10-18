String splitHashToPath(String hash) {
  return [
    hash.substring(0, 2),
    hash.substring(2, 4),
    hash.substring(4, 6),
    hash.substring(6, 8),
    hash.substring(8, 10)
  ].join("/");
}
