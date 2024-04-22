import 'package:melodink_client/features/tracks/domain/entities/track.dart';

class TrackJson {
  final int id;
  final String title;
  final String album;
  final Duration duration;
  final String tagsFormat;
  final String fileType;
  final String path;
  final String fileSignature;
  final TrackMetadataJson metadata;
  final DateTime dateAdded;

  TrackJson({
    required this.id,
    required this.title,
    required this.album,
    required this.duration,
    required this.tagsFormat,
    required this.fileType,
    required this.path,
    required this.fileSignature,
    required this.metadata,
    required this.dateAdded,
  });

  TrackJson.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        album = json['album'],
        duration = Duration(milliseconds: json['duration']),
        tagsFormat = json['tags_format'],
        fileType = json['file_type'],
        path = json['path'],
        fileSignature = json['file_signature'],
        metadata = TrackMetadataJson.fromJson(json['metadata']),
        dateAdded = DateTime.parse(json['date_added']);

  Track toTrack() {
    return Track(
      id: id,
      title: title,
      album: album,
      duration: duration,
      tagsFormat: tagsFormat,
      fileType: fileType,
      path: path,
      fileSignature: fileSignature,
      metadata: metadata.toTrackMetadata(),
      dateAdded: dateAdded,
    );
  }
}

class TrackMetadataJson {
  final int trackNumber;
  final int totalTracks;
  final int discNumber;
  final int totalDiscs;
  final String date;
  final int year;
  final String genre;
  final String lyrics;
  final String comment;
  final String acoustID;
  final String acoustIDFingerprint;
  final String artist;
  final String albumArtist;
  final String composer;
  final String copyright;

  TrackMetadataJson({
    required this.trackNumber,
    required this.totalTracks,
    required this.discNumber,
    required this.totalDiscs,
    required this.date,
    required this.year,
    required this.genre,
    required this.lyrics,
    required this.comment,
    required this.acoustID,
    required this.acoustIDFingerprint,
    required this.artist,
    required this.albumArtist,
    required this.composer,
    required this.copyright,
  });

  TrackMetadataJson.fromJson(Map<String, dynamic> json)
      : trackNumber = json['track_number'],
        totalTracks = json['total_tracks'],
        discNumber = json['disc_number'],
        totalDiscs = json['total_discs'],
        date = json['date'],
        year = json['year'],
        genre = json['genre'],
        lyrics = json['lyrics'],
        comment = json['comment'],
        acoustID = json['acoust_id'],
        acoustIDFingerprint = json['acoust_id_fingerprint'],
        artist = json['artist'],
        albumArtist = json['album_artist'],
        composer = json['composer'],
        copyright = json['copyright'];

  TrackMetadata toTrackMetadata() {
    return TrackMetadata(
      trackNumber: trackNumber,
      totalTracks: totalTracks,
      discNumber: discNumber,
      totalDiscs: totalDiscs,
      date: date,
      year: year,
      genre: genre,
      lyrics: lyrics,
      comment: comment,
      acoustID: acoustID,
      acoustIDFingerprint: acoustIDFingerprint,
      artist: artist,
      albumArtist: albumArtist,
      composer: composer,
      copyright: copyright,
    );
  }
}

