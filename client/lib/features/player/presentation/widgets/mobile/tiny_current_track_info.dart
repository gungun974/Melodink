import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:rxdart/rxdart.dart';

class TinyCurrentTrackInfo extends StatefulWidget {
  const TinyCurrentTrackInfo({super.key});

  @override
  State<TinyCurrentTrackInfo> createState() => _TinyCurrentTrackInfoState();
}

class _TinyCurrentTrackInfoState extends State<TinyCurrentTrackInfo> {
  final _audioHandler = sl<AudioHandler>();

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest2<Duration, MediaItem?, PositionData>(
        AudioService.position,
        _audioHandler.mediaItem,
        (position, duration) => PositionData(
          position: position,
          duration: duration?.duration ?? Duration.zero,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        if (state is! PlayerPlaying) {
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
                          image: state.currentTrack.cacheFile
                                  ?.getImageProvider() ??
                              NetworkImage(
                                "$appUrl/api/track/${state.currentTrack.id}/image",
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
                              state.currentTrack.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.currentTrack.metadata.artist,
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
                    stream: _audioHandler.playbackState,
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
                            _audioHandler.pause();
                            return;
                          }
                          _audioHandler.play();
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

                    final state = BlocProvider.of<PlayerCubit>(context).state;

                    Duration trackDuration = Duration.zero;

                    if (state is PlayerPlaying) {
                      trackDuration = state.currentTrack.duration;
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
