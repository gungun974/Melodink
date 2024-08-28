import 'package:audio_service/audio_service.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
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
    AudioService.position,
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
