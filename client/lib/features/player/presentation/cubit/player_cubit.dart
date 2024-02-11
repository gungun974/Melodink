import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/core/helpers/generate_unique_id.dart';
import 'package:melodink_client/features/player/domain/usecases/register_played_track.dart';
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
    }

    for (int j = 0; j < _nextTracks.length; j++) {
      final i = j + _previousTracks.length + _queueTracks.length;

      if (i > currentTrackIndex) {
        continue;
      }

      _previousTracks.add(_nextTracks.removeAt(j));
    }

    for (int i = _previousTracks.length - 1; i >= 0; i--) {
      if (i <= currentTrackIndex) {
        continue;
      }

      _nextTracks.insert(0, _previousTracks.removeAt(i));
    }
  }

  final RegisterPlayedTrack _registerPlayedTrack;
  final AudioHandler _audioHandler;

  PlayerCubit({
    required RegisterPlayedTrack registerPlayedTrack,
    required AudioHandler audioHandler,
  })  : _registerPlayedTrack = registerPlayedTrack,
        _audioHandler = audioHandler,
        super(PlayerStandby()) {
    _audioHandler.playbackState.listen(_updatePlaybackInfo);
    _audioHandler.playbackState.listen((_) => _watchPlayedTrack());
  }

  bool _isLoadingPlaylist = false;

  loadTracksPlaylist(List<Track> tracks, int startAt) async {
    _isLoadingPlaylist = true;
    _playlistTracks = tracks
        .map(
          (track) => IndexedTrack(
            track: track,
            index: generateUniqueID(),
          ),
        )
        .toList();

    if (isShuffled) {
      await shuffle(_playlistTracks[startAt].index);
      await _audioHandler.skipToQueueItem(0);
    } else {
      await unshuffle(_playlistTracks[startAt].index);
      await _audioHandler.skipToQueueItem(startAt);
    }

    await _audioHandler.play();

    _isLoadingPlaylist = false;
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
    _isLoadingPlaylist = true;

    _queueTracks.add(IndexedTrack(
      track: track,
      index: generateUniqueID(),
    ));

    final trackIndex = _getCurrentTrackIndex();

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

    _isLoadingPlaylist = false;
  }

  toogleShufle() async {
    final trackIndex = _getCurrentTrackIndex();

    if (trackIndex == null) {
      return;
    }

    _isLoadingPlaylist = true;

    if (isShuffled) {
      await unshuffle(_allTracks[trackIndex].index);
      _isLoadingPlaylist = false;
      return;
    }
    await shuffle(_allTracks[trackIndex].index);
    _isLoadingPlaylist = false;
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

    _updatePlaybackInfo(_audioHandler.playbackState.value);
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

    _updatePlaybackInfo(_audioHandler.playbackState.value);
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

  int? _getCurrentTrackIndex() {
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

  int? _lastQueueIndex;

  _updatePlaybackInfo(_) {
    final trackIndex = _getCurrentTrackIndex();

    if (trackIndex == null) {
      return;
    }

    if (!_isLoadingPlaylist) {
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
    _lastTrackDuration = const Duration();
    await _audioHandler.seek(newPosition);
    _startTrackTracking();
  }

  bool? _lastPlayingState;
  Track? _curentPlayedTrack;
  Duration _lastTrackDuration = const Duration();

  _watchPlayedTrack() async {
    final playingState = _audioHandler.playbackState.value.playing;

    if (_lastTrackDuration < _audioHandler.playbackState.value.position) {
      _lastTrackDuration = _audioHandler.playbackState.value.position;
    }

    if (_curentPlayedTrack != null && playingState != _lastPlayingState) {
      _lastPlayingState = playingState;

      if (playingState) {
        _startTrackTracking();
      } else {
        _finishTrackTracking(
          (_curentPlayedTrack?.duration ?? Duration.zero) -
                  _audioHandler.playbackState.value.position <
              const Duration(milliseconds: 750),
        );
        _lastTrackDuration = const Duration();
      }
    }

    final trackIndex = _getCurrentTrackIndex();

    if (trackIndex == null) {
      return;
    }

    if (_curentPlayedTrack?.id == _allTracks[trackIndex].track.id) {
      return;
    }

    if (_curentPlayedTrack != null) {
      _finishTrackTracking(true);
      _lastTrackDuration = const Duration();
    }

    _curentPlayedTrack = _allTracks[trackIndex].track;

    await Future.delayed(const Duration(milliseconds: 10));
    _startTrackTracking();
  }

  DateTime? trackedStartAt;
  DateTime? trackedFinishAt;

  Duration? trackedBeginAt;
  Duration? trackedEndedAt;

  _startTrackTracking() {
    final state = _audioHandler.playbackState.value;

    trackedStartAt = DateTime.now();
    trackedFinishAt = null;

    trackedBeginAt = state.position;
    trackedEndedAt = null;
  }

  _finishTrackTracking(bool hasTrackChanges) {
    trackedFinishAt = DateTime.now();

    trackedEndedAt = _lastTrackDuration;

    _registerTrackTracking(hasTrackChanges);
  }

  _registerTrackTracking(bool hasTrackChanges) {
    final currentTrack = _curentPlayedTrack;
    if (currentTrack == null) {
      return;
    }

    final startAt = trackedStartAt;
    final finishAt = trackedFinishAt;
    final beginAt = trackedBeginAt;
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

    if (finishAt.difference(startAt).inMilliseconds < 300) {
      return;
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

    _registerPlayedTrack(RegisterPlayedTrackParams(
      trackId: currentTrack.id,
      startAt: startAt,
      finishAt: finishAt,
      beginAt: beginAt,
      endedAt: endedAt,
      shuffle: isShuffled,
      skipped: skipped,
      trackEnded: trackEnded,
    ));

    trackedStartAt = null;
    trackedFinishAt = null;
    trackedBeginAt = null;
    trackedEndedAt = null;
  }
}
