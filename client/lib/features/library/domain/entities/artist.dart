import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';

class Artist extends Equatable {
  final int id;

  final String name;

  final List<Album> albums;
  final List<Album> appearAlbums;
  final List<Album> hasRoleAlbums;

  final String? localCover;

  const Artist({
    required this.id,
    required this.name,
    required this.albums,
    required this.appearAlbums,
    required this.hasRoleAlbums,
    this.localCover,
  });

  Artist copyWith({
    int? id,
    String? name,
    List<Album>? albums,
    List<Album>? appearAlbums,
    List<Album>? hasRoleAlbums,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      albums: albums ?? this.albums,
      appearAlbums: appearAlbums ?? this.appearAlbums,
      hasRoleAlbums: hasRoleAlbums ?? this.hasRoleAlbums,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        albums,
        appearAlbums,
        hasRoleAlbums,
        localCover,
      ];

  String getOriginalCoverUrl() {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    return "${AppApi().getServerUrl()}artist/$id/cover";
  }

  String getCompressedCoverUrl(TrackCompressedCoverQuality quality) {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    switch (quality) {
      case TrackCompressedCoverQuality.small:
        return "${AppApi().getServerUrl()}artist/$id/cover/small";
      case TrackCompressedCoverQuality.medium:
        return "${AppApi().getServerUrl()}artist/$id/cover/medium";
      case TrackCompressedCoverQuality.high:
        return "${AppApi().getServerUrl()}artist/$id/cover/high";
      default:
        return "${AppApi().getServerUrl()}artist/$id/cover";
    }
  }
}
