import 'package:equatable/equatable.dart';

class PlayedTrack extends Equatable {
  final int id;

  final int trackId;
  final DateTime startAt;
  final DateTime finishAt;

  final Duration beginAt;
  final Duration endedAt;

  final bool shuffle;

  final bool trackEnded;

  const PlayedTrack({
    required this.id,
    required this.trackId,
    required this.startAt,
    required this.finishAt,
    required this.beginAt,
    required this.endedAt,
    required this.shuffle,
    required this.trackEnded,
  });

  @override
  List<Object> get props => [
        id,
        trackId,
        startAt,
        finishAt,
        beginAt,
        endedAt,
        shuffle,
        trackEnded,
      ];
}
