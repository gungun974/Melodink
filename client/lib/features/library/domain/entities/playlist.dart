import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';

class Playlist extends Equatable {
  final int id;

  final String name;

  final String description;

  final List<MinimalTrack> tracks;

  final bool isDownloaded;

  final String? localCover;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
    this.isDownloaded = false,
    this.localCover,
  });

  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    List<MinimalTrack>? tracks,
    bool? isDownloaded,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tracks: tracks ?? this.tracks,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        tracks,
        isDownloaded,
        localCover,
      ];

  String getOriginalCoverUrl() {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    return "${AppApi().getServerUrl()}playlist/$id/cover";
  }

  String getCompressedCoverUrl(TrackCompressedCoverQuality quality) {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    switch (quality) {
      case TrackCompressedCoverQuality.small:
        return "${AppApi().getServerUrl()}playlist/$id/cover/small";
      case TrackCompressedCoverQuality.medium:
        return "${AppApi().getServerUrl()}playlist/$id/cover/medium";
      case TrackCompressedCoverQuality.high:
        return "${AppApi().getServerUrl()}playlist/$id/cover/high";
      default:
        return "${AppApi().getServerUrl()}playlist/$id/cover";
    }
  }
}
