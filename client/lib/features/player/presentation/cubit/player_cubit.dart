import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:path/path.dart' as p;

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

class IndexedTrack {
  final Track track;
  final int index;

  IndexedTrack({required this.track, required this.index});
}

class PlayerCubit extends Cubit<PlayerState> {
  List<Track> _playlistTracks = [];

  List<IndexedTrack> _previousTracks = [];

  List<IndexedTrack> _queueTracks = [];

  List<IndexedTrack> _nextTracks = [];

  List<IndexedTrack> get _allTracks => [
        ..._previousTracks,
        ..._queueTracks,
        ..._nextTracks,
      ];

  PlayerCubit() : super(PlayerStandby()) {
    _audioHandler.playbackState.listen(_updatePlaybackInfo);
  }

  int lastIndex = 0;

  final _audioHandler = sl<AudioHandler>();

  loadTracksPlaylist(List<Track> tracks, int startAt) async {
    _playlistTracks = tracks;

    _previousTracks = [];

    _queueTracks = [];

    _nextTracks = [];

    for (int i = 0; i < _playlistTracks.length; i++) {
      if (i < startAt) {
        _previousTracks.add(IndexedTrack(
          track: _playlistTracks[i],
          index: lastIndex++,
        ));
        continue;
      }

      _nextTracks.add(IndexedTrack(
        track: _playlistTracks[i],
        index: lastIndex++,
      ));
    }

    await _audioHandler.updateQueue(
      _allTracks.map((e) => _getTrackMediaItem(e.track, e.index)).toList(),
    );

    await _audioHandler.skipToQueueItem(startAt);

    await _audioHandler.play();
  }

  MediaItem _getTrackMediaItem(Track track, int index) {
    String filename = "audio${p.extension(track.path)}";

    if (audioFormat == "hls") {
      filename = "audio.m3u8";
    }

    if (audioFormat == "dash") {
      filename = "audio.mpd";
    }

    return MediaItem(
      id: track.id.toString(),
      title: track.title,
      artist: track.metadata.artist,
      album: track.album,
      genre: track.metadata.genre,
      artUri: Uri.parse(
        "$appUrl/api/track/${track.id}/image",
      ),
      extras: {
        'url':
            "$appUrl/api/track/${track.id}/audio/$audioFormat/$audioQuality/$filename",
      },
    );
  }

  _updatePlaybackInfo(PlaybackState state) {
    final index = state.queueIndex;
    if (index == null) {
      return;
    }

    final trackId = int.tryParse(_audioHandler.queue.value[index].id);

    if (trackId == null) {
      return;
    }

    final trackIndex =
        _playlistTracks.indexWhere((track) => track.id == trackId);

    if (trackIndex < 0) {
      return;
    }

    emit(
      PlayerPlaying(
        currentTrack: _playlistTracks[trackIndex],
      ),
    );
  }
}
