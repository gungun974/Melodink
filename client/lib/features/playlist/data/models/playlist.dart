import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:melodink_client/features/tracks/data/models/track.dart';

class PlaylistJson {
  final String id;
  final String name;
  final String description;
  final String albumArtist;
  final PlaylistType type;
  final List<TrackJson> tracks;

  PlaylistJson({
    required this.id,
    required this.name,
    required this.description,
    required this.albumArtist,
    required this.type,
    required this.tracks,
  });

  PlaylistJson.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        description = json['description'],
        albumArtist = json['album_artist'],
        type = parsePlaylistTypeJson(json['type']),
        tracks = (json['tracks'] as List)
            .map((track) => TrackJson.fromJson(track))
            .toList();

  Playlist toPlaylist() {
    return Playlist(
      id: id,
      name: name,
      description: description,
      albumArtist: albumArtist,
      type: type,
      tracks: tracks.map((track) => track.toTrack()).toList(),
    );
  }
}

PlaylistType parsePlaylistTypeJson(String type) {
  var playlistType = PlaylistType.custom;

  switch (type) {
    case "Artist":
      playlistType = PlaylistType.custom;
      break;
    case "Album":
      playlistType = PlaylistType.album;
      break;
    case "Custom":
      playlistType = PlaylistType.artist;
      break;
  }

  return playlistType;
}
