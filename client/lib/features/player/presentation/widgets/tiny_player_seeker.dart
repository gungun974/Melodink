import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:rxdart/rxdart.dart';

class TinyPlayerSeeker extends StatefulWidget {
  const TinyPlayerSeeker({super.key});

  @override
  State<TinyPlayerSeeker> createState() => _TinyPlayerSeekerState();
}

class _TinyPlayerSeekerState extends State<TinyPlayerSeeker> {
  final AudioController audioController = sl();

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest2<Duration, MediaItem?, PositionData>(
        AudioService.position,
        audioController.mediaItem,
        (position, duration) => PositionData(
          position: position,
          duration: duration?.duration ?? Duration.zero,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data;

        Duration trackDuration = Duration.zero;

        if (audioController.currentTrack.value != null) {
          trackDuration = audioController.currentTrack.value!.duration;
        }

        Duration position = positionData?.position ?? Duration.zero;
        Duration duration = positionData?.duration ?? trackDuration;

        if (position.inHours >= 8760) {
          position = Duration.zero;
        }

        if (duration.inHours >= 8760 || duration.inMilliseconds == 0) {
          duration = trackDuration;
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: position.inMilliseconds / duration.inMilliseconds,
            ),
          ),
        );
      },
    );
  }
}

class PositionData {
  final Duration position;
  final Duration duration;

  PositionData({
    required this.position,
    required this.duration,
  });
}
