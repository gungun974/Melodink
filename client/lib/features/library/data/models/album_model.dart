import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/data/models/track_model.dart';

class AlbumModel {
  final String id;

  final String name;

  final String albumArtist;

  final List<MinimalTrackModel> tracks;

  const AlbumModel({
    required this.id,
    required this.name,
    required this.albumArtist,
    required this.tracks,
  });

  Album toAlbum() {
    return Album(
      id: id,
      name: name,
      albumArtist: albumArtist,
      tracks: tracks
          .map(
            (track) => track.toMinimalTrack(),
          )
          .toList(),
    );
  }

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'],
      name: json['name'],
      albumArtist: json['album_artist'],
      tracks: (json['tracks'] as List)
          .map(
            (track) => MinimalTrackModel.fromJson(track),
          )
          .toList(),
    );
  }
}
