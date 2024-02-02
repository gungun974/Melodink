import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:rxdart/rxdart.dart';

class PlayerSeeker extends StatelessWidget {
  final AudioPlayer player;

  const PlayerSeeker({
    super.key,
    required this.player,
  });

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
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

          if (duration.inHours >= 8760 || duration.inMilliseconds == 0) {
            duration = trackDuration;
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                durationToTime(position),
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8.0),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.325,
                child: ProgressBar(
                  barHeight: 5.0,
                  thumbRadius: 7.0,
                  thumbColor: Colors.white,
                  baseBarColor: Colors.grey[800],
                  progressBarColor: Colors.white,
                  progress: positionData?.position ?? Duration.zero,
                  total: positionData?.duration ?? Duration.zero,
                  timeLabelLocation: TimeLabelLocation.none,
                  onSeek: (duration) async {
                    await player.seek(duration);
                    if (!player.playing) {
                      await player.pause();
                      await player.pause();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                durationToTime(duration),
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          );
        });
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}
