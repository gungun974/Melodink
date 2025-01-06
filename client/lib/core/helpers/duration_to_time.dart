String durationToTime(Duration time) {
  final absTime = time.abs();
  final minutes =
      absTime.inMinutes.remainder(Duration.minutesPerHour).toString();
  final seconds = absTime.inSeconds
      .remainder(Duration.secondsPerMinute)
      .toString()
      .padLeft(2, '0');

  final isNegative = time <= const Duration(seconds: -1);

  return (isNegative ? "-" : "") +
      (absTime.inHours > 0
          ? "${absTime.inHours}:${minutes.padLeft(2, "0")}:$seconds"
          : "$minutes:$seconds");
}
