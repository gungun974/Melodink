import 'package:melodink_client/features/track/domain/entities/track.dart';

class MinimalTrackModel {
  final int id;

  final String title;

  final Duration duration;

  final String album;

  final int trackNumber;
  final int discNumber;

  final String date;
  final int year;

  final String genre;

  final String artist;
  final String albumArtist;
  final String composer;

  final DateTime dateAdded;

  const MinimalTrackModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.album,
    required this.trackNumber,
    required this.discNumber,
    required this.date,
    required this.year,
    required this.genre,
    required this.artist,
    required this.albumArtist,
    required this.composer,
    required this.dateAdded,
  });

  MinimalTrack toMinimalTrack() {
    return MinimalTrack(
      id: id,
      title: title,
      duration: duration,
      album: album,
      trackNumber: trackNumber,
      discNumber: discNumber,
      date: date,
      year: year,
      genre: genre,
      artist: artist,
      albumArtist: albumArtist,
      composer: composer,
      dateAdded: dateAdded,
    );
  }

  factory MinimalTrackModel.fromJson(Map<String, dynamic> json) {
    return MinimalTrackModel(
      id: (json['id'] as num).toInt(),
      title: json['title'],
      duration: Duration(milliseconds: (json['duration'] as num).toInt()),
      album: json['album'],
      trackNumber: (json['track_number'] as num).toInt(),
      discNumber: (json['disc_number'] as num).toInt(),
      date: json['date'],
      year: (json['year'] as num).toInt(),
      genre: json['genre'],
      artist: json['artist'],
      albumArtist: json['album_artist'],
      composer: json['composer'],
      dateAdded: DateTime.parse(json['date_added']),
    );
  }
}