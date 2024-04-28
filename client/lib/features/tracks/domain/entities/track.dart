import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:melodink_client/features/tracks/domain/entities/track_file.dart';

part 'track.freezed.dart';

@freezed
class Track with _$Track {
  const factory Track({
    required int id,
    required String title,
    required String album,
    required Duration duration,
    required TrackFile? cacheFile,
    required String tagsFormat,
    required String fileType,
    required String path,
    required String fileSignature,
    required TrackMetadata metadata,
    required DateTime dateAdded,
  }) = _Track;
}

@freezed
class TrackMetadata with _$TrackMetadata {
  const factory TrackMetadata({
    required int trackNumber,
    required int totalTracks,
    required int discNumber,
    required int totalDiscs,
    required String date,
    required int year,
    required String genre,
    required String lyrics,
    required String comment,
    required String acoustID,
    required String acoustIDFingerprint,
    required String artist,
    required String albumArtist,
    required String composer,
    required String copyright,
  }) = _TrackMetadata;
}
