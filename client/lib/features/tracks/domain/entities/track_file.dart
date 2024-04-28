import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:path/path.dart' as p;

part 'track_file.freezed.dart';

enum AudioStreamFormat {
  file,
  hls,
  dash,
}

enum AudioStreamQuality {
  low,
  medium,
  high,
  max,
}

@freezed
class TrackFile with _$TrackFile {
  const TrackFile._();

  const factory TrackFile({
    required Uri uri,
    required Uri? image,
    required AudioStreamFormat format,
    required AudioStreamQuality quality,
  }) = _TrackFile;

  factory TrackFile.getNetworkTrackFile(
    Track track,
    AudioStreamFormat audioFormat,
    AudioStreamQuality audioQuality,
  ) {
    String filename = "audio${p.extension(track.path)}";

    if (audioFormat == AudioStreamFormat.hls) {
      filename = "audio.m3u8";
    }

    if (audioFormat == AudioStreamFormat.dash) {
      filename = "audio.mpd";
    }

    final audioFormatPath = switch (audioFormat) {
      AudioStreamFormat.file => "file",
      AudioStreamFormat.hls => "hls",
      AudioStreamFormat.dash => "dash",
    };

    final audioQualityPath = switch (audioQuality) {
      AudioStreamQuality.low => "low",
      AudioStreamQuality.medium => "medium",
      AudioStreamQuality.high => "high",
      AudioStreamQuality.max => "max",
    };

    return TrackFile(
      uri: Uri.parse(
        "$appUrl/api/track/${track.id}/audio/$audioFormatPath/$audioQualityPath/$filename",
      ),
      image: Uri.parse("$appUrl/api/track/${track.id}/image"),
      format: audioFormat,
      quality: audioQuality,
    );
  }

  ImageProvider<Object>? getImageProvider() {
    final currentImage = image;

    if (currentImage == null) {
      return null;
    }

    switch (currentImage.scheme) {
      case "file":
        return FileImage(
          File(currentImage.path),
        );
      case "asset":
        return AssetImage(
          currentImage.path.replaceFirst(RegExp(r'^/'), ''),
        );
      case "http":
      case "https":
        return NetworkImage(
          currentImage.toString(),
        );
    }

    return null;
  }
}
