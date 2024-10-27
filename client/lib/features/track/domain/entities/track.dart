import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';

class Track extends Equatable {
  final int id;

  final String title;
  final Duration duration;

  final String tagsFormat;
  final String fileType;

  final String fileSignature;

  final TrackMetadata metadata;

  final int sampleRate;
  final int? bitRate;
  final int? bitsPerRawSample;

  final DateTime dateAdded;

  const Track({
    required this.id,
    required this.title,
    required this.duration,
    required this.tagsFormat,
    required this.fileType,
    required this.fileSignature,
    required this.metadata,
    required this.sampleRate,
    required this.bitRate,
    required this.bitsPerRawSample,
    required this.dateAdded,
  });

  Track copyWith({
    int? id,
    String? title,
    Duration? duration,
    String? tagsFormat,
    String? fileType,
    String? fileSignature,
    TrackMetadata? metadata,
    int? sampleRate,
    int? bitRate,
    int? bitsPerRawSample,
    DateTime? dateAdded,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      tagsFormat: tagsFormat ?? this.tagsFormat,
      fileType: fileType ?? this.fileType,
      fileSignature: fileSignature ?? this.fileSignature,
      metadata: metadata ?? this.metadata,
      sampleRate: sampleRate ?? this.sampleRate,
      bitRate: bitRate ?? this.bitRate,
      bitsPerRawSample: bitsPerRawSample ?? this.bitsPerRawSample,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        duration,
        tagsFormat,
        fileType,
        fileSignature,
        metadata,
        sampleRate,
        bitRate,
        bitsPerRawSample,
        dateAdded,
      ];

  String getOriginalCoverUrl() {
    return "${AppApi().getServerUrl()}track/$id/cover";
  }

  String getCompressedCoverUrl(TrackCompressedCoverQuality quality) {
    switch (quality) {
      case TrackCompressedCoverQuality.small:
        return "${AppApi().getServerUrl()}track/$id/cover/small";
      case TrackCompressedCoverQuality.medium:
        return "${AppApi().getServerUrl()}track/$id/cover/medium";
      case TrackCompressedCoverQuality.high:
        return "${AppApi().getServerUrl()}track/$id/cover/high";
      default:
        return "${AppApi().getServerUrl()}track/$id/cover";
    }
  }

  Uri getOrignalCoverUri() {
    final url = getOriginalCoverUrl();
    Uri? uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri;
    }
    return Uri.parse("file://$url");
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

class TrackMetadata extends Equatable {
  final String album;
  final String albumId;

  final int trackNumber;
  final int totalTracks;

  final int discNumber;
  final int totalDiscs;

  final String date;
  final int year;

  final List<String> genres;
  final String lyrics;
  final String comment;

  final String acoustId;

  final String musicBrainzReleaseId;
  final String musicBrainzTrackId;
  final String musicBrainzRecordingId;

  final List<MinimalArtist> artists;
  final List<MinimalArtist> albumArtists;

  final String composer;

  const TrackMetadata({
    required this.album,
    required this.albumId,
    required this.trackNumber,
    required this.totalTracks,
    required this.discNumber,
    required this.totalDiscs,
    required this.date,
    required this.year,
    required this.genres,
    required this.lyrics,
    required this.comment,
    required this.acoustId,
    required this.musicBrainzReleaseId,
    required this.musicBrainzTrackId,
    required this.musicBrainzRecordingId,
    required this.artists,
    required this.albumArtists,
    required this.composer,
  });

  TrackMetadata copyWith({
    String? album,
    String? albumId,
    int? trackNumber,
    int? totalTracks,
    int? discNumber,
    int? totalDiscs,
    String? date,
    int? year,
    List<String>? genres,
    String? lyrics,
    String? comment,
    String? acoustId,
    String? musicBrainzReleaseId,
    String? musicBrainzTrackId,
    String? musicBrainzRecordingId,
    List<MinimalArtist>? artists,
    List<MinimalArtist>? albumArtists,
    String? composer,
  }) {
    return TrackMetadata(
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      trackNumber: trackNumber ?? this.trackNumber,
      totalTracks: totalTracks ?? this.totalTracks,
      discNumber: discNumber ?? this.discNumber,
      totalDiscs: totalDiscs ?? this.totalDiscs,
      date: date ?? this.date,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      lyrics: lyrics ?? this.lyrics,
      comment: comment ?? this.comment,
      acoustId: acoustId ?? this.acoustId,
      musicBrainzReleaseId: musicBrainzReleaseId ?? this.musicBrainzReleaseId,
      musicBrainzTrackId: musicBrainzTrackId ?? this.musicBrainzTrackId,
      musicBrainzRecordingId:
          musicBrainzRecordingId ?? this.musicBrainzRecordingId,
      artists: artists ?? this.artists,
      albumArtists: albumArtists ?? this.albumArtists,
      composer: composer ?? this.composer,
    );
  }

  @override
  List<Object?> get props => [
        album,
        albumId,
        trackNumber,
        totalTracks,
        discNumber,
        totalDiscs,
        date,
        year,
        genres,
        lyrics,
        comment,
        acoustId,
        musicBrainzReleaseId,
        musicBrainzTrackId,
        musicBrainzRecordingId,
        artists,
        albumArtists,
        composer,
      ];
}
