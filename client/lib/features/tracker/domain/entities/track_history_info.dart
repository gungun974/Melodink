import 'package:equatable/equatable.dart';

class TrackHistoryInfo extends Equatable {
  const TrackHistoryInfo({
    required this.trackId,
    required this.lastPlayedDate,
    required this.playedCount,
  });

  final int trackId;

  final DateTime? lastPlayedDate;
  final int playedCount;

  TrackHistoryInfo copyWith({
    int? trackId,
    DateTime? Function()? lastPlayedDate,
    int? playedCount,
  }) {
    return TrackHistoryInfo(
      trackId: trackId ?? this.trackId,
      lastPlayedDate:
          lastPlayedDate != null ? lastPlayedDate() : this.lastPlayedDate,
      playedCount: playedCount ?? this.playedCount,
    );
  }

  @override
  List<Object?> get props => [lastPlayedDate, playedCount];

  @override
  bool get stringify => true;
}
