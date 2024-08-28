import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';

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
    return "${AppApi().getServerUrl()}track/$id/audio";
  }

  String getCoverUrl() {
    return "${AppApi().getServerUrl()}track/$id/cover";
  }
}
