import 'package:equatable/equatable.dart';

class MinimalTrack extends Equatable {
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

  const MinimalTrack({
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

  @override
  List<Object> get props => [
        id,
        title,
        duration,
        album,
        trackNumber,
        discNumber,
        date,
        year,
        genre,
        artist,
        albumArtist,
        composer,
        dateAdded,
      ];

  String getUrl() {
    return "http://127.0.0.1:8000/track/$id/audio";
  }

  String getCoverUrl() {
    return "http://127.0.0.1:8000/track/$id/cover";
  }
}
