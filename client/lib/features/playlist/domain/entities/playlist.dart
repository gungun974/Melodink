import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';

enum PlaylistType {
  album,
  artist,
  custom,
  allTracks,
}

class Playlist extends Equatable {
  final String id;
  final String name;
  final String description;
  final String albumArtist;
  final PlaylistType type;
  final List<Track> tracks;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.albumArtist,
    required this.type,
    required this.tracks,
  });

  @override
  List<Object> get props => [
        id,
        name,
        description,
        albumArtist,
        type,
        tracks,
      ];
}
