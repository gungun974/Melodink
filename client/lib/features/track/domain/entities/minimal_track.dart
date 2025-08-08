import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/helpers/double_to_string_without_zero.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/tracker/domain/entities/track_history_info.dart';

class MinimalTrack extends Equatable {
  final int id;
  final String title;

  final Duration duration;

  final String album;
  final int albumId;

  final int trackNumber;
  final int discNumber;

  final String date;
  final int year;

  final List<String> genres;

  final List<MinimalArtist> artists;
  final List<MinimalArtist> albumArtists;
  final String composer;

  final String fileType;

  final String fileSignature;

  final int sampleRate;
  final int? bitRate;
  final int? bitsPerRawSample;

  final double score;

  final DateTime dateAdded;

  final TrackHistoryInfo? historyInfo;

  const MinimalTrack({
    required this.id,
    required this.title,
    required this.duration,
    required this.album,
    required this.albumId,
    required this.trackNumber,
    required this.discNumber,
    required this.date,
    required this.year,
    required this.genres,
    required this.artists,
    required this.albumArtists,
    required this.composer,
    required this.fileType,
    required this.fileSignature,
    required this.sampleRate,
    required this.bitRate,
    required this.bitsPerRawSample,
    required this.dateAdded,
    required this.score,
    this.historyInfo,
  });

  MinimalTrack copyWith({
    int? id,
    String? title,
    Duration? duration,
    String? album,
    int? albumId,
    int? trackNumber,
    int? discNumber,
    String? date,
    int? year,
    List<String>? genres,
    List<MinimalArtist>? artists,
    List<MinimalArtist>? albumArtists,
    String? composer,
    String? fileType,
    String? fileSignature,
    int? sampleRate,
    int? bitRate,
    int? bitsPerRawSample,
    DateTime? dateAdded,
    double? score,
    TrackHistoryInfo? Function()? historyInfo,
  }) {
    return MinimalTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      date: date ?? this.date,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      artists: artists ?? this.artists,
      albumArtists: albumArtists ?? this.albumArtists,
      composer: composer ?? this.composer,
      fileType: fileType ?? this.fileType,
      fileSignature: fileSignature ?? this.fileSignature,
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
        album,
        albumId,
        trackNumber,
        discNumber,
        date,
        year,
        genres,
        artists,
        albumArtists,
        composer,
        fileType,
        fileSignature,
        sampleRate,
        bitRate,
        bitsPerRawSample,
        dateAdded,
        score,
        historyInfo,
      ];

  List<MinimalArtist> getVirtualAlbumArtists() {
    final List<MinimalArtist> newArtists = List.from(albumArtists);

    if (newArtists.isEmpty && artists.isNotEmpty) {
      return [artists.first];
    }

    newArtists.sort();

    return newArtists;
  }

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
