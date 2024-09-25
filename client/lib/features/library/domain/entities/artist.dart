import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';

class Artist extends Equatable {
  final String id;

  final String name;

  final List<Album> albums;
  final List<Album> appearAlbums;

  final String? localCover;

  const Artist({
    required this.id,
    required this.name,
    required this.albums,
    required this.appearAlbums,
    this.localCover,
  });

  Artist copyWith({
    String? id,
    String? name,
    List<Album>? albums,
    List<Album>? appearAlbums,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      albums: albums ?? this.albums,
      appearAlbums: appearAlbums ?? this.appearAlbums,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        albums,
        appearAlbums,
        localCover,
      ];

  String getCoverUrl() {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    return "${AppApi().getServerUrl()}artist/$id/cover";
  }
}

class MinimalArtist extends Equatable {
  final String id;
  final String name;

  const MinimalArtist({
    required this.id,
    required this.name,
  });

  MinimalArtist copyWith({
    String? id,
    String? name,
  }) {
    return MinimalArtist(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
      ];
}
