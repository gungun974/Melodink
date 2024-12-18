import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';

class Album extends Equatable {
  final String id;

  final String name;

  final List<MinimalArtist> albumArtists;

  final List<MinimalTrack> tracks;

  final bool isDownloaded;
  final bool downloadTracks;

  final String? localCover;

  const Album({
    required this.id,
    required this.name,
    required this.albumArtists,
    required this.tracks,
    this.isDownloaded = false,
    this.downloadTracks = false,
    this.localCover,
  });

  Album copyWith({
    String? id,
    String? name,
    List<MinimalArtist>? albumArtists,
    List<MinimalTrack>? tracks,
    bool? isDownloaded,
    bool? downloadTracks,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      albumArtists: albumArtists ?? this.albumArtists,
      tracks: tracks ?? this.tracks,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadTracks: downloadTracks ?? this.downloadTracks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        albumArtists,
        tracks,
        isDownloaded,
        downloadTracks,
        localCover,
      ];

  String getOriginalCoverUrl() {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    return "${AppApi().getServerUrl()}album/$id/cover";
  }

  Uri getOrignalCoverUri() {
    final url = getOriginalCoverUrl();
    Uri? uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri;
    }
    return Uri.parse("file://$url");
  }

  String getCompressedCoverUrl(TrackCompressedCoverQuality quality) {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    switch (quality) {
      case TrackCompressedCoverQuality.small:
        return "${AppApi().getServerUrl()}album/$id/cover/small";
      case TrackCompressedCoverQuality.medium:
        return "${AppApi().getServerUrl()}album/$id/cover/medium";
      case TrackCompressedCoverQuality.high:
        return "${AppApi().getServerUrl()}album/$id/cover/high";
      default:
        return "${AppApi().getServerUrl()}album/$id/cover";
    }
  }

  Uri getCompressedCoverUri(TrackCompressedCoverQuality quality) {
    final url = getCompressedCoverUrl(quality);
    Uri? uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri;
    }
    return Uri.parse("file://$url");
  }
}
