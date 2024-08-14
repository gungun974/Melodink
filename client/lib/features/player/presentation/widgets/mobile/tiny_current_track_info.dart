import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:rxdart/rxdart.dart';

class TinyCurrentTrackInfo extends StatefulWidget {
  const TinyCurrentTrackInfo({super.key});

  @override
  State<TinyCurrentTrackInfo> createState() => _TinyCurrentTrackInfoState();
}

class _TinyCurrentTrackInfoState extends State<TinyCurrentTrackInfo> {
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
    return StreamBuilder(
      stream: audioController.currentTrack.stream,
      builder: (context, snapshot) {
        final currentTrack = snapshot.data;
        if (currentTrack == null) {
          return Container();
        }
        return Container(
          color: Colors.black87,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        FadeInImage(
                          height: 40,
                          placeholder: const AssetImage(
                            "assets/melodink_track_cover_not_found.png",
                          ),
                          image: NetworkImage(
                            currentTrack.getCoverUrl(),
                          ),
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              "assets/melodink_track_cover_not_found.png",
                              width: 40,
                              height: 40,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTrack.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTrack.albumArtist,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  StreamBuilder<PlaybackState>(
                    stream: audioController.playbackState,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return IconButton(
                        padding: const EdgeInsets.only(right: 4),
                        constraints: const BoxConstraints(),
                        icon: isPlaying
                            ? const AdwaitaIcon(
                                AdwaitaIcons.media_playback_pause)
                            : const AdwaitaIcon(
                                AdwaitaIcons.media_playback_start),
                        iconSize: 32.0,
                        onPressed: () async {
                          if (isPlaying) {
                            await audioController.pause();
                            return;
                          }
                          await audioController.play();
                        },
                      );
                    },
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: StreamBuilder<PositionData>(
                  stream: positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;

                    Duration trackDuration = Duration.zero;

                    if (audioController.currentTrack.value != null) {
                      trackDuration =
                          audioController.currentTrack.value!.duration;
                    }

                    Duration position = positionData?.position ?? Duration.zero;
                    Duration duration = positionData?.duration ?? trackDuration;

                    if (position.inHours >= 8760) {
                      position = Duration.zero;
                    }

                    if (duration.inHours >= 8760 ||
                        duration.inMilliseconds == 0) {
                      duration = trackDuration;
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          value:
                              position.inMilliseconds / duration.inMilliseconds,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
