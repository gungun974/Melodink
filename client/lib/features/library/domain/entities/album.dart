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

  final DateTime lastTrackDateAdded;

  final bool isDownloaded;
  final bool downloadTracks;

  final String? localCover;
  final String? coverSignature;

  const Album({
    required this.id,
    required this.name,
    required this.albumArtists,
    required this.tracks,
    required this.lastTrackDateAdded,
    this.isDownloaded = false,
    this.downloadTracks = false,
    this.localCover,
    this.coverSignature,
  });

  Album copyWith({
    String? id,
    String? name,
    List<MinimalArtist>? albumArtists,
    List<MinimalTrack>? tracks,
    DateTime? lastTrackDateAdded,
    bool? isDownloaded,
    bool? downloadTracks,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      albumArtists: albumArtists ?? this.albumArtists,
      tracks: tracks ?? this.tracks,
      lastTrackDateAdded: lastTrackDateAdded ?? this.lastTrackDateAdded,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadTracks: downloadTracks ?? this.downloadTracks,
      coverSignature: coverSignature,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        albumArtists,
        tracks,
        lastTrackDateAdded,
        isDownloaded,
        downloadTracks,
        localCover,
        coverSignature,
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

  String getYear() {
    final years = <int>{};

    for (var i = 0; i < tracks.length; i++) {
      years.add(tracks[i].year);
    }

    final yearsList = years.toList()..sort();
    final buffer = StringBuffer();

    int? start;
    int? end;

    for (var i = 0; i < yearsList.length; i++) {
      if (start == null) {
        start = yearsList[i];
        end = start;
      } else if (yearsList[i] == end! + 1) {
        end = yearsList[i];
      } else {
        if (start == end) {
          buffer.write('$start');
        } else {
          buffer.write('$start-$end');
        }
        buffer.write(', ');
        start = yearsList[i];
        end = start;
      }
    }

    if (start != null) {
      if (start == end) {
        buffer.write('$start');
      } else {
        buffer.write('$start-$end');
      }
    }

    return buffer.toString();
  }
}
