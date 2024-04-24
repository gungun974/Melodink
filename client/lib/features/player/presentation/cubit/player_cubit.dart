import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/core/helpers/generate_unique_id.dart';
import 'package:melodink_client/features/player/domain/repositories/played_track_repository.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;

abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object> get props => [];
}

class PlayerStandby extends PlayerState {}

class PlayerPlaying extends PlayerState {
  final Track currentTrack;

  final List<Track> previousTrack;

  final List<Track> queueTracks;

  final List<Track> nextTracks;

  final bool isShuffled;

  const PlayerPlaying({
    required this.currentTrack,
    required this.previousTrack,
    required this.queueTracks,
    required this.nextTracks,
    required this.isShuffled,
  });

  @override
  List<Object> get props => [
        currentTrack,
        previousTrack,
        queueTracks,
        nextTracks,
      ];
}

class IndexedTrack {
  final Track track;
  final String index;

  IndexedTrack({required this.track, required this.index});
}

class PlayerCubit extends Cubit<PlayerState> {
  List<IndexedTrack> _playlistTracks = [];

  List<IndexedTrack> _previousTracks = [];

  final List<IndexedTrack> _queueTracks = [];

  List<IndexedTrack> _nextTracks = [];

  List<IndexedTrack> get _allTracks => [
        ..._previousTracks,
        ..._queueTracks,
        ..._nextTracks,
      ];

  bool isShuffled = false;

  _updatePlaylistTracks(int currentTrackIndex) {
    for (int j = 0; j < _queueTracks.length; j++) {
      final i = j + _previousTracks.length;

      if (i > currentTrackIndex) {
        continue;
      }

      _previousTracks.add(_queueTracks.removeAt(j));
      j--;
    }

    for (int j = 0; j < _nextTracks.length; j++) {
      final i = j + _previousTracks.length + _queueTracks.length;

      if (i > currentTrackIndex) {
        continue;
      }

      _previousTracks.add(_nextTracks.removeAt(j));
      j--;
    }

    for (int i = _previousTracks.length - 1; i >= 0; i--) {
      if (i <= currentTrackIndex) {
        continue;
      }

      _nextTracks.insert(0, _previousTracks.removeAt(i));
    }
  }

  final PlayedTrackRepository _playedTrackRepository;
  final AudioHandler _audioHandler;

  PlayerCubit({
    required PlayedTrackRepository playedTrackRepository,
    required AudioHandler audioHandler,
  })  : _playedTrackRepository = playedTrackRepository,
        _audioHandler = audioHandler,
        super(PlayerStandby()) {
    _audioHandler.customEvent.listen(_updatePlaybackInfo);
    _audioHandler.customEvent.listen(_watchPlayedTrack2);
    _audioHandler.playbackState.listen((_) => _watchPlayedTrack1());
  }

  final _isLoadingPlaylist = Mutex();

  loadTracksPlaylist(List<Track> tracks, int startAt) async {
    await _isLoadingPlaylist.protect(() async {
      _playlistTracks = tracks
          .map(
            (track) => IndexedTrack(
              track: track,
              index: generateUniqueID(),
            ),
          )
          .toList();

      await _audioHandler.stop();

      if (isShuffled) {
        await shuffle(_playlistTracks[startAt].index);
        await _audioHandler.skipToQueueItem(0);
      } else {
        await unshuffle(_playlistTracks[startAt].index);
        await _audioHandler.skipToQueueItem(startAt);
      }

      _audioHandler.play();
    });
  }

  // ignore: unused_element
  _debugTracks() {
    print("PREV ------------------------");

    for (final (index, track) in _previousTracks.indexed) {
      print("$index : ${track.track.title}");
    }

    print("QUEUE ------------------------");

    for (final (index, track) in _queueTracks.indexed) {
      print("$index : ${track.track.title}");
    }

    print("NEXT ------------------------");

    for (final (index, track) in _nextTracks.indexed) {
      print("$index : ${track.track.title}");
    }

    print("ALL ------------------------");

    for (final (index, track) in _allTracks.indexed) {
      print("$index : ${track.track.title}");
    }

    print("\n---------------------------------------------\n");
  }

  addTrackToQueue(Track track) async {
    await _isLoadingPlaylist.protect(() async {
      _queueTracks.add(IndexedTrack(
        track: track,
        index: generateUniqueID(),
      ));

      final trackIndex = _manualGetCurrentTrackIndex();

      if (trackIndex == null) {
        return;
      }

      _updatePlaylistTracks(trackIndex);

      await _audioHandler.updateQueue(
        _allTracks.map((e) => _getTrackMediaItem(e.track, e.index)).toList(),
      );

      emit(
        PlayerPlaying(
          currentTrack: _allTracks[trackIndex].track,
          previousTrack: _previousTracks.map((e) => e.track).toList(),
          queueTracks: _queueTracks.map((e) => e.track).toList(),
          nextTracks: _nextTracks.map((e) => e.track).toList(),
          isShuffled: isShuffled,
        ),
      );
    });
  }

  toogleShufle() async {
    final trackIndex = _manualGetCurrentTrackIndex();

    if (trackIndex == null) {
      return;
    }

    await _isLoadingPlaylist.protect(() async {
      if (isShuffled) {
        await unshuffle(_allTracks[trackIndex].index);
        return;
      }
      await shuffle(_allTracks[trackIndex].index);
    });
  }

  shuffle(String extraIndex) async {
    final startAt =
        _playlistTracks.indexWhere((track) => track.index == extraIndex);

    isShuffled = true;

    _previousTracks = [];

    _nextTracks = [..._playlistTracks];

    _previousTracks.add(_nextTracks.removeAt(startAt));

    _nextTracks.shuffle();

    _updatePlaylistTracks(0);

    await _audioHandler.updateQueue(
      _allTracks.map((e) => _getTrackMediaItem(e.track, e.index)).toList(),
    );

    _lastQueueIndex = null;
  }

  unshuffle(String extraIndex) async {
    final startAt =
        _playlistTracks.indexWhere((track) => track.index == extraIndex);

    isShuffled = false;

    _previousTracks = [];

    _nextTracks = [];

    if (startAt < 0) {
      return;
    }

    for (int i = 0; i < _playlistTracks.length; i++) {
      if (i <= startAt) {
        _previousTracks.add(_playlistTracks[i]);
        continue;
      }

      _nextTracks.add(_playlistTracks[i]);
    }

    _updatePlaylistTracks(startAt);

    await _audioHandler.updateQueue(
      _allTracks.map((e) => _getTrackMediaItem(e.track, e.index)).toList(),
    );

    _lastQueueIndex = null;
  }

  MediaItem _getTrackMediaItem(Track track, String index) {
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
        "index": index,
      },
    );
  }

  int? _manualGetCurrentTrackIndex() {
    final state = _audioHandler.playbackState.value;
    final index = state.queueIndex;

    if (index == null) {
      return null;
    }

    final extraIndex = _audioHandler.queue.value[index].extras?["index"];

    if (extraIndex == null) {
      return null;
    }

    final trackIndex =
        _allTracks.indexWhere((track) => track.index == extraIndex);

    if (trackIndex < 0) {
      return null;
    }

    return trackIndex;
  }

  int? _getCurrentTrackIndex(int index) {
    final extraIndex = _audioHandler.queue.value[index].extras?["index"];

    if (extraIndex == null) {
      return null;
    }

    final trackIndex =
        _allTracks.indexWhere((track) => track.index == extraIndex);

    if (trackIndex < 0) {
      return null;
    }

    return trackIndex;
  }

  int? _lastQueueIndex;

  _updatePlaybackInfo(dynamic event) {
    if (event is! Map) {
      return;
    }

    if (event["type"] != "trackIndex") {
      return;
    }
    final trackIndex = _getCurrentTrackIndex(event["trackIndex"]);

    if (trackIndex == null) {
      return;
    }

    if (!_isLoadingPlaylist.isLocked) {
      _updatePlaylistTracks(trackIndex);
    }

    if (trackIndex == _lastQueueIndex) {
      return;
    }

    _lastQueueIndex = trackIndex;

    emit(
      PlayerPlaying(
        currentTrack: _allTracks[trackIndex].track,
        previousTrack: _previousTracks.map((e) => e.track).toList(),
        queueTracks: _queueTracks.map((e) => e.track).toList(),
        nextTracks: _nextTracks.map((e) => e.track).toList(),
        isShuffled: isShuffled,
      ),
    );
  }

  seek(Duration newPosition) async {
    _finishTrackTracking(false);
    await _audioHandler.seek(newPosition);
    _startTrackTracking();
  }

  bool? _lastPlayingState;
  Track? _curentPlayedTrack;
  Duration _lastTrackDuration = const Duration();

  _watchPlayedTrack1() async {
    final playingState = _audioHandler.playbackState.value.playing;

    if (_lastTrackDuration < _audioHandler.playbackState.value.position) {
      _lastTrackDuration = _audioHandler.playbackState.value.position;
    }

    if (_curentPlayedTrack != null && playingState != _lastPlayingState) {
      _lastPlayingState = playingState;

      if ((_curentPlayedTrack?.duration ?? Duration.zero) -
              _audioHandler.playbackState.value.position <
          const Duration(milliseconds: 750)) {
        return;
      }

      if (playingState) {
        _startTrackTracking();
      } else {
        _finishTrackTracking(false);
      }
    }
  }

  _watchPlayedTrack2(dynamic event) async {
    if (event is! Map) {
      return;
    }

    if (event["type"] != "trackIndex") {
      return;
    }

    final trackIndex = _getCurrentTrackIndex(event["trackIndex"]);

    if (trackIndex == null) {
      return;
    }

    if (_curentPlayedTrack?.id == _allTracks[trackIndex].track.id) {
      return;
    }

    if (_curentPlayedTrack != null) {
      _finishTrackTracking(true);
    }

    _curentPlayedTrack = _allTracks[trackIndex].track;

    await Future.delayed(const Duration(milliseconds: 65));
    _startTrackTracking();
  }

  DateTime? trackedStartAt;
  DateTime? trackedFinishAt;

  Duration? trackedBeginAt;
  Duration? trackedEndedAt;

  bool startTrackingTrack = false;

  _startTrackTracking() {
    final state = _audioHandler.playbackState.value;

    trackedStartAt = DateTime.now();
    trackedFinishAt = null;

    trackedBeginAt = state.position;
    trackedEndedAt = null;

    _lastTrackDuration = const Duration();

    startTrackingTrack = true;
  }

  _finishTrackTracking(bool hasTrackChanges) {
    if (!startTrackingTrack) {
      return;
    }

    startTrackingTrack = false;

    trackedFinishAt = DateTime.now();

    trackedEndedAt = _lastTrackDuration;

    _lastTrackDuration = const Duration();

    _registerTrackTracking(hasTrackChanges);
  }

  _registerTrackTracking(bool hasTrackChanges) {
    final currentTrack = _curentPlayedTrack;
    if (currentTrack == null) {
      return;
    }

    final startAt = trackedStartAt;
    final finishAt = trackedFinishAt;
    Duration? beginAt = trackedBeginAt;
    final endedAt = trackedEndedAt;

    if (startAt == null) {
      return;
    }
    if (finishAt == null) {
      return;
    }
    if (beginAt == null) {
      return;
    }
    if (endedAt == null) {
      return;
    }

    if (beginAt.inMilliseconds < 0) {
      beginAt = const Duration();
    }

    bool skipped = false;
    bool trackEnded = false;

    if (hasTrackChanges) {
      if (currentTrack.duration - endedAt > const Duration(seconds: 5)) {
        skipped = true;
      } else {
        trackEnded = true;
      }
    }

    _playedTrackRepository.addPlayedTrack(
      trackId: currentTrack.id,
      startAt: startAt,
      finishAt: finishAt,
      beginAt: beginAt,
      endedAt: endedAt,
      shuffle: isShuffled,
      skipped: skipped,
      trackEnded: trackEnded,
    );

    trackedStartAt = null;
    trackedFinishAt = null;
    trackedBeginAt = null;
    trackedEndedAt = null;
  }
}
