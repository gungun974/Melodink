import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/features/player/domain/usecases/fetch_audio_stream.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:rxdart/rxdart.dart';

abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object> get props => [];
}

class PlayerStandby extends PlayerState {}

class PlayerPlaying extends PlayerState {
  final Track currentTrack;

  const PlayerPlaying({
    required this.currentTrack,
  });

  @override
  List<Object> get props => [
        currentTrack,
      ];
}

class PlayerCubit extends Cubit<PlayerState> {
  final FetchAudioStream fetchAudioStream;

  final player = AudioPlayer();

  PlayerCubit({
    required this.fetchAudioStream,
  }) : super(PlayerStandby());

  void loadTrack(Track track) async {
    emit(
      PlayerPlaying(
        currentTrack: track,
      ),
    );

    final targetingTrack = track.id;

    final response = await fetchAudioStream(
      Params(
        trackId: targetingTrack,
      ),
    );

    response.match(
      (_) {},
      (url) async {
        final currentState = state;

        if (currentState is! PlayerPlaying) {
          return;
        }

        if (currentState.currentTrack.id != targetingTrack) {
          return;
        }

        final source = AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: track.id.toString(),
            title: track.title,
            artist: track.metadata.artist,
            album: track.album,
            genre: track.metadata.genre,
            artUri: Uri.parse(
              "$appUrl/api/track/${track.id}/image",
            ),
          ),
        );

        await player.setAudioSource(source);

        player.play();
      },
    );
  }

  playOrPause() {
    final currentState = state;

    if (currentState is! PlayerPlaying) {
      return;
    }

    if (player.playing) {
      player.pause();
      return;
    }
    player.play();
  }
}
