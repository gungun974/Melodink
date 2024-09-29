import 'package:melodink_client/features/library/data/models/artist_model.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class MinimalTrackModel {
  final int id;

  final String title;

  final Duration duration;

  final String album;
  final String albumId;

  final int trackNumber;
  final int discNumber;

  final String date;
  final int year;

  final List<String> genres;

  final List<MinimalArtistModel> artists;
  final List<MinimalArtistModel> albumArtists;
  final String composer;

  final DateTime dateAdded;

  const MinimalTrackModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.album,
    required this.albumId,
    required this.trackNumber,
    required this.discNumber,
    required this.date,
    required this.year,
    required this.genres,
    required this.artists,
    required this.albumArtists,
    required this.composer,
    required this.dateAdded,
  });

  MinimalTrack toMinimalTrack() {
    return MinimalTrack(
      id: id,
      title: title,
      duration: duration,
      album: album,
      albumId: albumId,
      trackNumber: trackNumber,
      discNumber: discNumber,
      date: date,
      year: year,
      genres: genres,
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
      dateAdded: dateAdded,
    );
  }

  factory MinimalTrackModel.fromMinimalTrack(MinimalTrack track) {
    return MinimalTrackModel(
      id: track.id,
      title: track.title,
      duration: track.duration,
      album: track.album,
      albumId: track.albumId,
      trackNumber: track.trackNumber,
      discNumber: track.discNumber,
      date: track.date,
      year: track.year,
      genres: track.genres,
      artists: track.artists
          .map(
            (artist) => MinimalArtistModel.fromMinimalArtist(artist),
          )
          .toList(),
      albumArtists: track.albumArtists
          .map(
            (artist) => MinimalArtistModel.fromMinimalArtist(artist),
          )
          .toList(),
      composer: track.composer,
      dateAdded: track.dateAdded,
    );
  }

  factory MinimalTrackModel.fromJson(Map<String, dynamic> json) {
    return MinimalTrackModel(
      id: (json['id'] as num).toInt(),
      title: json['title'],
      duration: Duration(milliseconds: (json['duration'] as num).toInt()),
      album: json['album'],
      albumId: json['album_id'],
      trackNumber: (json['track_number'] as num).toInt(),
      discNumber: (json['disc_number'] as num).toInt(),
      date: json['date'],
      year: (json['year'] as num).toInt(),
      genres: List<String>.from(json['genres']),
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
      dateAdded: DateTime.parse(json['date_added']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration.inMilliseconds,
      'album': album,
      'album_id': albumId,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'date': date,
      'year': year,
      'genres': genres,
      'artists': artists
          .map(
            (artist) => artist.toJson(),
          )
          .toList(),
      'album_artists': albumArtists
          .map(
            (artist) => artist.toJson(),
          )
          .toList(),
      'composer': composer,
      'date_added': dateAdded.toIso8601String(),
    };
  }
}
