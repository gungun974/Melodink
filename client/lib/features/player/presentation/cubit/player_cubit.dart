import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';

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

const numberOfPreloadTrack = 15;

class PlayerCubit extends Cubit<PlayerState> {
  final player = AudioPlayer();

  final _playerPlaylist = ConcatenatingAudioSource(
    useLazyPreparation: true,
    children: [],
  );

  final List<Track> _trackPlaylist = [];

  int? getTrackIndexBaseOnPlayerPlaylist(int playerIndex) {
    if (playerIndex >= _playerPlaylist.length || playerIndex < 0) {
      return null;
    }

    final playlistTrack = _playerPlaylist[playerIndex];

    if (playlistTrack is! IndexedAudioSource) {
      return null;
    }

    final tag = playlistTrack.tag;

    if (tag is! MediaItem) {
      return null;
    }

    final trackId = int.tryParse(tag.id);

    if (trackId == null) {
      return null;
    }

    if (playerIndex < _trackPlaylist.length) {
      if (_trackPlaylist[playerIndex].id == trackId) {
        return playerIndex;
      }
    }

    final trackIndex =
        _trackPlaylist.lastIndexWhere((track) => track.id == trackId);

    if (trackIndex < 0) {
      return null;
    }

    return trackIndex;
  }

  PlayerCubit() : super(PlayerStandby()) {
    player.setAudioSource(_playerPlaylist);

    player.currentIndexStream.listen((_) {
      _updateCurrentTrackInfo();

      _prepareNextTrackFromCurrent(numberOfPreloadTrack);
    });
  }

  _updateCurrentTrackInfo() {
    final index = player.currentIndex;

    if (index == null) {
      return;
    }

    final trackIndex = getTrackIndexBaseOnPlayerPlaylist(index);

    if (trackIndex == null) {
      return;
    }

    final track = _trackPlaylist[trackIndex];

    emit(
      PlayerPlaying(
        currentTrack: track,
      ),
    );
  }

  _prepareNextTrackFromCurrent(int preLoad) async {
    final index = player.currentIndex;

    if (index == null) {
      return;
    }

    return _prepareNextTrack(index, preLoad);
  }

  DateTime lastPrepareNextTrack = DateTime.now();

  _prepareNextTrack(int currentIndex, int preLoad) async {
    final currentTime = DateTime.now();

    lastPrepareNextTrack = currentTime;

    return _prepareNextTrackWithInvalated(currentIndex, preLoad, currentTime);
  }

  _prepareNextTrackWithInvalated(
      int currentIndex, int preLoad, DateTime currentPrepareDate) async {
    if (preLoad <= 0) {
      return;
    }

    final currentTrackIndex = getTrackIndexBaseOnPlayerPlaylist(currentIndex);

    if (currentTrackIndex == null) {
      return;
    }

    if (currentTrackIndex + 1 >= _trackPlaylist.length) {
      await _playerPlaylist.removeRange(
          currentIndex + 1, _playerPlaylist.length);
      return;
    }

    final nextWantedTrack = _trackPlaylist[currentTrackIndex + 1];

    final nextTrackIndex = getTrackIndexBaseOnPlayerPlaylist(currentIndex + 1);

    if (nextTrackIndex == null) {
      final source = _getTrackAudioSource(nextWantedTrack);

      if (currentPrepareDate != lastPrepareNextTrack) {
        return;
      }

      await _playerPlaylist.add(source);

      return _prepareNextTrack(currentIndex + 1, preLoad - 1);
    }

    if (_trackPlaylist[nextTrackIndex].id != nextWantedTrack.id) {
      await _playerPlaylist.removeAt(currentIndex + 1);
      final source = _getTrackAudioSource(nextWantedTrack);

      if (currentPrepareDate != lastPrepareNextTrack) {
        return;
      }
      return _prepareNextTrack(currentIndex + 1, preLoad - 1);
    }

    if (currentPrepareDate != lastPrepareNextTrack) {
      return;
    }

    return _prepareNextTrackWithInvalated(
        currentIndex + 1, preLoad - 1, currentPrepareDate);
  }

  void addTrackToPlaylist(Track track) async {
    _trackPlaylist.add(track);

    _prepareNextTrackFromCurrent(numberOfPreloadTrack);
  }

  void startPlaylist() async {
    if (player.playing) {
      await player.stop();
    }

    await _playerPlaylist.clear();

    if (_trackPlaylist.isEmpty) {
      return;
    }

    final source = _getTrackAudioSource(_trackPlaylist[0]);

    await _playerPlaylist.add(source);

    player.play();

    await player.seek(Duration.zero, index: 0);

    _updateCurrentTrackInfo();
    await _prepareNextTrack(0, 5);
  }

  AudioSource _getTrackAudioSource(Track track) {
    return AudioSource.uri(
      Uri.parse(
        "$appUrl/api/track/${track.id}/audio/$audioFormat/$audioQuality",
      ),
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
