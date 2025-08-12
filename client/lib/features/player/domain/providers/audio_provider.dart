import 'dart:io';

import 'package:color_thief_flutter/color_thief_flutter.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

@Riverpod(keepAlive: true)
Stream<AudioControllerPositionData> audioControllerPositionDataStream(Ref ref) {
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

@Riverpod(keepAlive: true)
Stream<Track?> currentTrackStream(Ref ref) async* {
  final audioController = ref.watch(audioControllerProvider);

  await for (final track in audioController.currentTrack.stream) {
    yield track;
    final _ = ref.refresh(currentPlayerVolumeProvider);
  }
}

@riverpod
bool isCurrentTrack(Ref ref, int trackId) {
  final currentTrackStream = ref.watch(currentTrackStreamProvider);

  final currentTrack = currentTrackStream.valueOrNull;

  return currentTrack?.id == trackId;
}

@riverpod
Future<List<List<int>>?> currentTrackPalette(Ref ref) async {
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

  final imageUrl = downloadedTrack?.getCoverUrl() ??
      currentTrack.getCompressedCoverUrl(
        TrackCompressedCoverQuality.medium,
      );

  Uri? uri = Uri.tryParse(imageUrl);

  ImageProvider imageProvider;

  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    imageProvider = FileImage(await ImageCacheManager.getImage(uri));
  } else {
    imageProvider = FileImage(File(imageUrl));
  }

  final image = await getImageFromProvider(imageProvider);

  final palette = await getPaletteFromImage(image, 5, 5);

  return palette;
}

@riverpod
double currentPlayerVolume(Ref ref) {
  final audioController = ref.watch(audioControllerProvider);

  return audioController.getVolume();
}

@riverpod
class ShowTrackRemainingDuration extends _$ShowTrackRemainingDuration {
  final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

  @override
  bool build() {
    loadSavedState();
    return false;
  }

  loadSavedState() async {
    state = await _asyncPrefs.getBool("showTrackRemainingDuration") ?? false;
  }

  toggle() {
    state = !state;
    _asyncPrefs.setBool("showTrackRemainingDuration", state);
  }
}
