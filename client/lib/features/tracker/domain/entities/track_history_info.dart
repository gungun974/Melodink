import 'package:equatable/equatable.dart';

class TrackHistoryInfo extends Equatable {
  const TrackHistoryInfo({
    required this.trackId,
    required this.lastPlayedDate,
    required this.playedCount,
    required this.computed,
  });

  final int trackId;

  final DateTime? lastPlayedDate;
  final int playedCount;

  final bool computed;

  TrackHistoryInfo copyWith({
    int? trackId,
    DateTime? Function()? lastPlayedDate,
    int? playedCount,
    bool? computed,
  }) {
    return TrackHistoryInfo(
      trackId: trackId ?? this.trackId,
      lastPlayedDate:
          lastPlayedDate != null ? lastPlayedDate() : this.lastPlayedDate,
      playedCount: playedCount ?? this.playedCount,
      computed: computed ?? this.computed,
    );
  }

  @override
  List<Object?> get props => [lastPlayedDate, playedCount];

  @override
  bool get stringify => true;
}
