import 'package:melodink_client/features/library/data/models/artist_model.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class TrackModel {
  final int id;

  final String title;
  final Duration duration;

  final String tagsFormat;
  final String fileType;

  final String fileSignature;
  final String coverSignature;

  final TrackMetadataModel metadata;

  final int sampleRate;
  final int? bitRate;
  final int? bitsPerRawSample;

  final DateTime dateAdded;

  final double score;

  const TrackModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.tagsFormat,
    required this.fileType,
    required this.fileSignature,
    required this.coverSignature,
    required this.metadata,
    required this.sampleRate,
    required this.bitRate,
    required this.bitsPerRawSample,
    required this.dateAdded,
    required this.score,
  });

  Track toTrack() {
    return Track(
      id: id,
      title: title,
      duration: duration,
      tagsFormat: tagsFormat,
      fileType: fileType,
      fileSignature: fileSignature,
      coverSignature: coverSignature,
      metadata: metadata.toTrackMetadata(),
      sampleRate: sampleRate,
      bitRate: bitRate,
      bitsPerRawSample: bitsPerRawSample,
      dateAdded: dateAdded,
      score: score,
    );
  }

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: (json['id'] as num).toInt(),
      title: json['title'],
      duration: Duration(milliseconds: (json['duration'] as num).toInt()),
      tagsFormat: json['tags_format'],
      fileType: json['file_type'],
      fileSignature: json['file_signature'],
      coverSignature: json['cover_signature'],
      metadata: TrackMetadataModel.fromJson(json['metadata']),
      sampleRate: (json['sample_rate'] as num).toInt(),
      bitRate:
          json['bit_rate'] != null ? (json['bit_rate'] as num).toInt() : null,
      bitsPerRawSample: json['bits_per_raw_sample'] != null
          ? (json['bits_per_raw_sample'] as num).toInt()
          : null,
      dateAdded: DateTime.parse(json['date_added']).toLocal(),
      score: (json['score'] as num).toDouble(),
    );
  }
}

class TrackMetadataModel {
  final String album;
  final int albumId;

  final int trackNumber;
  final int totalTracks;

  final int discNumber;
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

  final List<MinimalArtistModel> artists;
  final List<MinimalArtistModel> albumArtists;

  final String composer;

  const TrackMetadataModel({
    required this.album,
    required this.albumId,
    required this.trackNumber,
    required this.totalTracks,
    required this.discNumber,
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
    required this.artists,
    required this.albumArtists,
    required this.composer,
  });

  TrackMetadata toTrackMetadata() {
    return TrackMetadata(
      album: album,
      albumId: albumId,
      trackNumber: trackNumber,
      totalTracks: totalTracks,
      discNumber: discNumber,
      totalDiscs: totalDiscs,
      date: date,
      year: year,
      genres: genres,
      lyrics: lyrics,
      comment: comment,
      acoustId: acoustId,
      musicBrainzReleaseId: musicBrainzReleaseId,
      musicBrainzTrackId: musicBrainzTrackId,
      musicBrainzRecordingId: musicBrainzRecordingId,
      artists: artists
          .map(
            (artist) => artist.toMinimalArtist(),
          )
          .toList(),
      albumArtists: albumArtists
          .map(
            (artist) => artist.toMinimalArtist(),
          )
          .toList(),
      composer: composer,
    );
  }

  factory TrackMetadataModel.fromJson(Map<String, dynamic> json) {
    return TrackMetadataModel(
      album: json['album'],
      albumId: json['album_id'],
      trackNumber: (json['track_number'] as num).toInt(),
      totalTracks: (json['total_tracks'] as num).toInt(),
      discNumber: (json['disc_number'] as num).toInt(),
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
      artists: (json['artists'] as List)
          .map(
            (artist) => MinimalArtistModel.fromJson(artist),
          )
          .toList(),
      albumArtists: (json['album_artists'] as List)
          .map(
            (artist) => MinimalArtistModel.fromJson(artist),
          )
          .toList(),
      composer: json['composer'],
    );
  }
}
