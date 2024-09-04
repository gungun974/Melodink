import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class Album extends Equatable {
  final String id;

  final String name;

  final String albumArtist;

  final List<MinimalTrack> tracks;

  final bool isDownloaded;

  final String? localCover;

  const Album({
    required this.id,
    required this.name,
    required this.albumArtist,
    required this.tracks,
    this.isDownloaded = false,
    this.localCover,
  });

  Album copyWith({
    String? id,
    String? name,
    String? albumArtist,
    List<MinimalTrack>? tracks,
    bool? isDownloaded,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      albumArtist: albumArtist ?? this.albumArtist,
      tracks: tracks ?? this.tracks,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        albumArtist,
        tracks,
        isDownloaded,
        localCover,
      ];

  String getCoverUrl() {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    return "${AppApi().getServerUrl()}album/$id/cover";
  }
}
