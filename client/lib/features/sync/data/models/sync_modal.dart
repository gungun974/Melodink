import 'package:melodink_client/features/sync/data/models/album_model.dart';
import 'package:melodink_client/features/sync/data/models/artist_model.dart';
import 'package:melodink_client/features/sync/data/models/playlist_model.dart';
import 'package:melodink_client/features/sync/data/models/track_model.dart';

class FullSyncModel {
  final List<TrackModel> tracks;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<PlaylistModel> playlists;

  final DateTime date;

  const FullSyncModel({
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.playlists,
    required this.date,
  });

  factory FullSyncModel.fromJson(Map<String, dynamic> json) {
    return FullSyncModel(
      tracks: (List<Map<String, dynamic>>.from(json['tracks']))
          .map(TrackModel.fromJson)
          .toList(),
      albums: (List<Map<String, dynamic>>.from(json['albums']))
          .map(AlbumModel.fromJson)
          .toList(),
      artists: (List<Map<String, dynamic>>.from(json['artists']))
          .map(ArtistModel.fromJson)
          .toList(),
      playlists: (List<Map<String, dynamic>>.from(json['playlists']))
          .map(PlaylistModel.fromJson)
          .toList(),
      date: DateTime.parse(json['date']),
    );
  }
}

class PartialSyncModel {
  final List<TrackModel> newTracks;
  final List<AlbumModel> newAlbums;
  final List<ArtistModel> newArtists;
  final List<PlaylistModel> newPlaylists;

  final List<int> deletedTracks;
  final List<int> deletedAlbums;
  final List<int> deletedArtists;
  final List<int> deletedPlaylists;

  final DateTime date;

  const PartialSyncModel({
    required this.newTracks,
    required this.newAlbums,
    required this.newArtists,
    required this.newPlaylists,
    required this.deletedTracks,
    required this.deletedAlbums,
    required this.deletedArtists,
    required this.deletedPlaylists,
    required this.date,
  });

  factory PartialSyncModel.fromJson(Map<String, dynamic> json) {
    return PartialSyncModel(
      newTracks: (List<Map<String, dynamic>>.from(json["new"]['tracks']))
          .map(TrackModel.fromJson)
          .toList(),
      newAlbums: (List<Map<String, dynamic>>.from(json["new"]['albums']))
          .map(AlbumModel.fromJson)
          .toList(),
      newArtists: (List<Map<String, dynamic>>.from(json["new"]['artists']))
          .map(ArtistModel.fromJson)
          .toList(),
      newPlaylists: (List<Map<String, dynamic>>.from(json["new"]['playlists']))
          .map(PlaylistModel.fromJson)
          .toList(),
      deletedTracks: List<int>.from(json["del"]['tracks']),
      deletedAlbums: List<int>.from(json["del"]['albums']),
      deletedArtists: List<int>.from(json["del"]['artists']),
      deletedPlaylists: List<int>.from(json["del"]['playlists']),
      date: DateTime.parse(json['date']),
    );
  }
}
