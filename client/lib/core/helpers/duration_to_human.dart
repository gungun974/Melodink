String durationToHuman(Duration duration) {
  final List<String> splited = [];

  final days = duration.inDays;
  final hours = duration.inHours.remainder(60);
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (days > 0) {
    splited.add("$days day${days > 1 ? 's' : ''}");
  }

  if (duration.inHours > 0) {
    splited.add("$hours hour${hours > 1 ? 's' : ''}");
  }

  if (duration.inMinutes > 0) {
    splited.add("$minutes minute${minutes > 1 ? 's' : ''}");
  }

  if (duration.inSeconds > 0 && days < 0) {
    splited.add("$seconds seconde${seconds > 1 ? 's' : ''}");
  }

  var human = "";

  for (final (index, element) in splited.indexed) {
    if (index == splited.length - 1) {
      human += "and ";
    }

    human += element;

    if (index == splited.length - 1) {
      continue;
    }
    human += ", ";
  }

  return human;
}
