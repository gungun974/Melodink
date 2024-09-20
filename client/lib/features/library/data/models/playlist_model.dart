import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/data/models/track_model.dart';

class PlaylistModel {
  final int id;

  final String name;

  final String description;

  final List<MinimalTrackModel> tracks;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
  });

  Playlist toPlaylist() {
    return Playlist(
      id: id,
      name: name,
      description: description,
      tracks: tracks
          .map(
            (track) => track.toMinimalTrack(),
          )
          .toList(),
    );
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      tracks: (json['tracks'] as List)
          .map(
            (track) => MinimalTrackModel.fromJson(track),
          )
          .toList(),
    );
  }
}
