import 'package:equatable/equatable.dart';

class Track extends Equatable {
  final int id;
  final String title;
  final String album;
  final Duration duration;
  final String tagsFormat;
  final String fileType;
  final String path;
  final String fileSignature;
  final TrackMetadata metadata;
  final DateTime dateAdded;

  const Track({
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

  @override
  List<Object> get props => [
        id,
        title,
        album,
        duration,
        tagsFormat,
        fileType,
        path,
        fileSignature,
        metadata,
        dateAdded,
      ];
}

class TrackMetadata extends Equatable {
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

  const TrackMetadata({
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

  @override
  List<Object> get props => [
        trackNumber,
        totalTracks,
        discNumber,
        totalDiscs,
        date,
        year,
        genre,
        lyrics,
        comment,
        acoustID,
        acoustIDFingerprint,
        artist,
        albumArtist,
        composer,
        copyright,
      ];
}
