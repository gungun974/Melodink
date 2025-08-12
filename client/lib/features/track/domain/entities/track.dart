import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/helpers/double_to_string_without_zero.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/tracker/domain/entities/track_history_info.dart';

class Track extends Equatable {
  final int id;

  final String title;
  final Duration duration;

  final String tagsFormat;
  final String fileType;

  final String fileSignature;
  final String coverSignature;

  final List<Album> albums;
  final List<Artist> artists;

  final int trackNumber;
  final int discNumber;

  final TrackMetadata metadata;

  final int sampleRate;
  final int? bitRate;
  final int? bitsPerRawSample;

  final DateTime dateAdded;

  final double score;

  final TrackHistoryInfo? historyInfo;

  const Track({
    required this.id,
    required this.title,
    required this.duration,
    required this.tagsFormat,
    required this.fileType,
    required this.fileSignature,
    required this.coverSignature,
    required this.albums,
    required this.artists,
    required this.trackNumber,
    required this.discNumber,
    required this.metadata,
    required this.sampleRate,
    required this.bitRate,
    required this.bitsPerRawSample,
    required this.dateAdded,
    required this.score,
    this.historyInfo,
  });

  Track copyWith({
    int? id,
    String? title,
    Duration? duration,
    String? tagsFormat,
    String? fileType,
    String? fileSignature,
    String? coverSignature,
    List<Album>? albums,
    List<Artist>? artists,
    int? trackNumber,
    int? discNumber,
    TrackMetadata? metadata,
    int? sampleRate,
    int? bitRate,
    int? bitsPerRawSample,
    DateTime? dateAdded,
    double? score,
    TrackHistoryInfo? Function()? historyInfo,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      tagsFormat: tagsFormat ?? this.tagsFormat,
      fileType: fileType ?? this.fileType,
      fileSignature: fileSignature ?? this.fileSignature,
      coverSignature: coverSignature ?? this.coverSignature,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      metadata: metadata ?? this.metadata,
      sampleRate: sampleRate ?? this.sampleRate,
      bitRate: bitRate ?? this.bitRate,
      bitsPerRawSample: bitsPerRawSample ?? this.bitsPerRawSample,
      dateAdded: dateAdded ?? this.dateAdded,
      score: score ?? this.score,
      historyInfo: historyInfo != null ? historyInfo() : this.historyInfo,
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
        coverSignature,
        albums,
        artists,
        trackNumber,
        discNumber,
        metadata,
        sampleRate,
        bitRate,
        bitsPerRawSample,
        dateAdded,
        score,
        historyInfo,
      ];

  String getUrl(AppSettingAudioQuality quality) {
    switch (quality) {
      case AppSettingAudioQuality.low:
        return "${AppApi().getServerUrl()}track/$id/audio/low/transcode";
      case AppSettingAudioQuality.medium:
        return "${AppApi().getServerUrl()}track/$id/audio/medium/transcode";
      case AppSettingAudioQuality.high:
        return "${AppApi().getServerUrl()}track/$id/audio/high/transcode";
      default:
        return "${AppApi().getServerUrl()}track/$id/audio";
    }
  }

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

  String getQualityText() {
    if (bitsPerRawSample != null) {
      return "$bitsPerRawSample-Bit ${doubleToStringWithoutZero(sampleRate / 1000)}KHz $fileType";
    }

    if (bitRate != null) {
      return "${doubleToStringWithoutZero(bitRate! / 1000)} kbps $fileType";
    }

    return "Unknown $fileType";
  }
}

class TrackMetadata extends Equatable {
  final int totalTracks;
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

  final String composer;

  const TrackMetadata({
    required this.totalTracks,
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
    required this.composer,
  });

  TrackMetadata copyWith({
    int? totalTracks,
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
    String? composer,
  }) {
    return TrackMetadata(
      totalTracks: totalTracks ?? this.totalTracks,
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
      composer: composer ?? this.composer,
    );
  }

  @override
  List<Object?> get props => [
        totalTracks,
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
        composer,
      ];
}
