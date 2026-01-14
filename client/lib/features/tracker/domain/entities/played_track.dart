import 'package:equatable/equatable.dart';

class PlayedTrack extends Equatable {
  final int internalId;
  final int? serverId;

  final int trackId;
  final DateTime startAt;
  final DateTime finishAt;

  final Duration beginAt;
  final Duration endedAt;

  final bool shuffle;

  final bool trackEnded;

  final Duration trackDuration;

  const PlayedTrack({
    required this.internalId,
    required this.serverId,
    required this.trackId,
    required this.startAt,
    required this.finishAt,
    required this.beginAt,
    required this.endedAt,
    required this.shuffle,
    required this.trackEnded,
    required this.trackDuration,
  });

  @override
  List<Object?> get props => [
    internalId,
    serverId,
    trackId,
    startAt,
    finishAt,
    beginAt,
    endedAt,
    shuffle,
    trackEnded,
    trackDuration,
  ];
}
