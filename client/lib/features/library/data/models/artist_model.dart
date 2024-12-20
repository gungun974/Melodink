import 'package:melodink_client/features/library/data/models/album_model.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';

class ArtistModel {
  final String id;

  final String name;

  final List<AlbumModel> albums;
  final List<AlbumModel> appearAlbums;
  final List<AlbumModel> hasRoleAlbums;

  final DateTime lastTrackDateAdded;

  const ArtistModel({
    required this.id,
    required this.name,
    required this.albums,
    required this.appearAlbums,
    required this.hasRoleAlbums,
    required this.lastTrackDateAdded,
  });

  Artist toArtist() {
    return Artist(
      id: id,
      name: name,
      albums: albums
          .map(
            (album) => album.toAlbum(),
          )
          .toList(),
      appearAlbums: appearAlbums
          .map(
            (album) => album.toAlbum(),
          )
          .toList(),
      hasRoleAlbums: hasRoleAlbums
          .map(
            (album) => album.toAlbum(),
          )
          .toList(),
      lastTrackDateAdded: lastTrackDateAdded,
    );
  }

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id'],
      name: json['name'],
      albums: (json['albums'] as List)
          .map(
            (album) => AlbumModel.fromJson(album),
          )
          .toList(),
      appearAlbums: (json['appear_albums'] as List)
          .map(
            (album) => AlbumModel.fromJson(album),
          )
          .toList(),
      hasRoleAlbums: (json['has_role_albums'] as List)
          .map(
            (album) => AlbumModel.fromJson(album),
          )
          .toList(),
      lastTrackDateAdded:
          DateTime.parse(json['last_track_date_added']).toLocal(),
    );
  }
}

class MinimalArtistModel {
  final String id;

  final String name;

  const MinimalArtistModel({
    required this.id,
    required this.name,
  });

  MinimalArtist toMinimalArtist() {
    return MinimalArtist(
      id: id,
      name: name,
    );
  }

  factory MinimalArtistModel.fromMinimalArtist(MinimalArtist artist) {
    return MinimalArtistModel(
      id: artist.id,
      name: artist.name,
    );
  }

  factory MinimalArtistModel.fromJson(Map<String, dynamic> json) {
    return MinimalArtistModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
