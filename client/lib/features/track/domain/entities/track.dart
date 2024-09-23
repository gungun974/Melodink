import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';

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

  MinimalTrack copyWith({
    int? id,
    String? title,
    Duration? duration,
    String? album,
    int? trackNumber,
    int? discNumber,
    String? date,
    int? year,
    String? genre,
    String? artist,
    String? albumArtist,
    String? composer,
    DateTime? dateAdded,
  }) {
    return MinimalTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      album: album ?? this.album,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      date: date ?? this.date,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      artist: artist ?? this.artist,
      albumArtist: albumArtist ?? this.albumArtist,
      composer: composer ?? this.composer,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  List<Object?> get props => [
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

  String getVirtualAlbumArtist() {
    if (albumArtist.isNotEmpty) {
      return albumArtist;
    }

    return artist;
  }

  String getUrl() {
    return "${AppApi().getServerUrl()}track/$id/audio";
  }

  String getCoverUrl() {
    return "${AppApi().getServerUrl()}track/$id/cover";
  }

  Uri getCoverUri() {
    final url = getCoverUrl();
    Uri? uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri;
    }
    return Uri.parse("file://$url");
  }
}
