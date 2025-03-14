class SharedPlayedTrackModel {
  final int id;
  final int internalDeviceId;

  final String deviceId;

  final int trackId;

  final DateTime startAt;
  final DateTime finishAt;

  final Duration beginAt;
  final Duration endedAt;

  final bool shuffle;

  final bool trackEnded;

  final DateTime sharedAt;

  final Duration trackDuration;

  const SharedPlayedTrackModel({
    required this.id,
    required this.internalDeviceId,
    required this.deviceId,
    required this.trackId,
    required this.startAt,
    required this.finishAt,
    required this.beginAt,
    required this.endedAt,
    required this.shuffle,
    required this.trackEnded,
    required this.trackDuration,
    required this.sharedAt,
  });

  factory SharedPlayedTrackModel.fromJson(Map<String, dynamic> json) {
    return SharedPlayedTrackModel(
      id: json['id'] as int,
      internalDeviceId: json['internal_device_id'] as int,
      deviceId: json['device_id'] as String,
      trackId: json['track_id'] as int,
      startAt: DateTime.parse(json['start_at'] as String),
      finishAt: DateTime.parse(json['finish_at'] as String),
      beginAt: Duration(milliseconds: json['begin_at'] as int),
      endedAt: Duration(milliseconds: json['ended_at'] as int),
      shuffle: json['shuffle'] as bool,
      trackEnded: json['track_ended'] as bool,
      trackDuration: Duration(milliseconds: json['track_duration'] as int),
      sharedAt: DateTime.parse(json['shared_at'] as String),
    );
  }
}
