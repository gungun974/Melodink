import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';

class Playlist extends Equatable {
  final int id;

  final String name;

  final String description;

  final List<Track> tracks;

  final bool isDownloaded;

  final String? localCover;
  final String coverSignature;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
    this.isDownloaded = false,
    this.localCover,
    required this.coverSignature,
  });

  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    List<Track>? tracks,
    bool? isDownloaded,
    String? coverSignature,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tracks: tracks ?? this.tracks,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      coverSignature: coverSignature ?? this.coverSignature,
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
        coverSignature,
      ];

  String getOriginalCoverUrl() {
    final cover = localCover;
    if (cover != null) {
      return cover;
    }

    return "${AppApi().getServerUrl()}playlist/$id/cover";
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
        return "${AppApi().getServerUrl()}playlist/$id/cover/small";
      case TrackCompressedCoverQuality.medium:
        return "${AppApi().getServerUrl()}playlist/$id/cover/medium";
      case TrackCompressedCoverQuality.high:
        return "${AppApi().getServerUrl()}playlist/$id/cover/high";
      default:
        return "${AppApi().getServerUrl()}playlist/$id/cover";
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
