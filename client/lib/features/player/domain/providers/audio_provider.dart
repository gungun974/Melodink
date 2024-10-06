import 'dart:io';

import 'package:color_thief_flutter/color_thief_flutter.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'audio_provider.g.dart';

class AudioControllerPositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  AudioControllerPositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}

@riverpod
Stream<AudioControllerPositionData> audioControllerPositionDataStream(
  AudioControllerPositionDataStreamRef ref,
) {
  final audioController = ref.watch(audioControllerProvider);

  return Rx.combineLatest3<Duration, PlaybackState, MediaItem?,
      AudioControllerPositionData>(
    AudioController.quickPosition,
    audioController.playbackState,
    audioController.mediaItem,
    (position, playerState, duration) {
      return AudioControllerPositionData(
        position: position,
        bufferedPosition: playerState.bufferedPosition,
        duration: duration?.duration ?? Duration.zero,
      );
    },
  );
}

@riverpod
Stream<MinimalTrack?> currentTrackStream(CurrentTrackStreamRef ref) async* {
  final audioController = ref.watch(audioControllerProvider);

  await for (final track in audioController.currentTrack.stream) {
    yield track;
  }
}

@riverpod
bool isCurrentTrack(
  IsCurrentTrackRef ref,
  int trackId,
) {
  final currentTrackStream = ref.watch(currentTrackStreamProvider);

  final currentTrack = currentTrackStream.valueOrNull;

  return currentTrack?.id == trackId;
}

@riverpod
Future<List<List<int>>?> currentTrackPalette(
  CurrentTrackPaletteRef ref,
) async {
  final currentTrackStream = ref.watch(currentTrackStreamProvider);

  final currentTrack = currentTrackStream.valueOrNull;

  if (currentTrack == null) {
    return null;
  }

  final downloadedTrack = ref
      .watch(
        isTrackDownloadedProvider(currentTrack.id),
      )
      .valueOrNull;

  final imageUrl = downloadedTrack?.getCoverUrl() ?? currentTrack.getCoverUrl();

  Uri? uri = Uri.tryParse(imageUrl);

  ImageProvider imageProvider;

  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    imageProvider = AppImageCacheProvider(uri);
  } else {
    imageProvider = FileImage(File(imageUrl));
  }

  final image = await getImageFromProvider(imageProvider);

  final palette = await getPaletteFromImage(image, 5, 5);

  return palette;
}
