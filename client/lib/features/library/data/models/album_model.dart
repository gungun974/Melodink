import 'package:melodink_client/features/library/data/models/artist_model.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/data/models/track_model.dart';

class AlbumModel {
  final String id;

  final String name;

  final List<MinimalArtistModel> albumArtists;

  final List<MinimalTrackModel> tracks;

  const AlbumModel({
    required this.id,
    required this.name,
    required this.albumArtists,
    required this.tracks,
  });

  Album toAlbum() {
    return Album(
      id: id,
      name: name,
      albumArtists: albumArtists
          .map(
            (artist) => artist.toMinimalArtist(),
          )
          .toList(),
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
      albumArtists: (json['album_artists'] as List)
          .map(
            (artist) => MinimalArtistModel.fromJson(artist),
          )
          .toList(),
      tracks: (json['tracks'] as List)
          .map(
            (track) => MinimalTrackModel.fromJson(track),
          )
          .toList(),
    );
  }
}
