class TrackModel {
  final int id;
  final int userId;

  final String title;
  final Duration duration;

  final String tagsFormat;
  final String fileType;

  final String fileSignature;
  final String coverSignature;

  final List<int> albums;
  final List<int> artists;

  final int trackNumber;
  final int discNumber;

  final TrackMetadataModel metadata;

  final int sampleRate;
  final int? bitRate;
  final int? bitsPerRawSample;

  final double score;

  final DateTime dateAdded;

  const TrackModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.duration,
    required this.tagsFormat,
    required this.fileType,
    required this.fileSignature,
    required this.coverSignature,
    required this.albums,
    required this.artists,
    required this.trackNumber,
    required this.discNumber,
    required this.metadata,
    required this.sampleRate,
    required this.bitRate,
    required this.bitsPerRawSample,
    required this.dateAdded,
    required this.score,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      duration: Duration(milliseconds: json['duration']),
      tagsFormat: json['tags_format'],
      fileType: json['file_type'],
      fileSignature: json['file_signature'],
      coverSignature: json['cover_signature'],
      albums: List<int>.from(json['albums']),
      artists: List<int>.from(json['artists']),
      trackNumber: json['track_number'],
      discNumber: json['disc_number'],
      metadata: TrackMetadataModel.fromJson(json['metadata']),
      sampleRate: json['sample_rate'],
      bitRate: json['bit_rate'],
      bitsPerRawSample: json['bits_per_raw_sample'],
      dateAdded: DateTime.parse(json['date_added']).toLocal(),
      score: (json['score'] as num).toDouble(),
    );
  }
}

class TrackMetadataModel {
  final int totalTracks;
  final int totalDiscs;

  final String date;
  final int year;

  final List<String> genres;
  final String lyrics;
  final String comment;

  final String acoustId;

  final String musicBrainzReleaseId;
  final String musicBrainzTrackId;
  final String musicBrainzRecordingId;

  final String composer;

  const TrackMetadataModel({
    required this.totalTracks,
    required this.totalDiscs,
    required this.date,
    required this.year,
    required this.genres,
    required this.lyrics,
    required this.comment,
    required this.acoustId,
    required this.musicBrainzReleaseId,
    required this.musicBrainzTrackId,
    required this.musicBrainzRecordingId,
    required this.composer,
  });

  factory TrackMetadataModel.fromJson(Map<String, dynamic> json) {
    return TrackMetadataModel(
      totalTracks: (json['total_tracks'] as num).toInt(),
      totalDiscs: (json['total_discs'] as num).toInt(),
      date: json['date'],
      year: (json['year'] as num).toInt(),
      genres: List<String>.from(json['genres']),
      lyrics: json['lyrics'],
      comment: json['comment'],
      acoustId: json['acoust_id'],
      musicBrainzReleaseId: json['music_brainz_release_id'],
      musicBrainzTrackId: json['music_brainz_track_id'],
      musicBrainzRecordingId: json['music_brainz_recording_id'],
      composer: json['composer'],
    );
  }
}
