import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/generated/messages.g.dart';
import 'package:mutex/mutex.dart';
import 'package:rxdart/rxdart.dart';

late final AudioController _audioController;

Future<AudioController> initAudioService() async {
  _audioController = await AudioService.init(
    builder: () => AudioController(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'fr.gungun974.melodink.audio',
      androidNotificationChannelName: 'Melodink Audio Service',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  MelodinkHostPlayerApiInfo.setUp(_audioController);

  return _audioController;
}

class AudioController extends BaseAudioHandler
    implements MelodinkHostPlayerApiInfo {
  final api = MelodinkHostPlayerApi();

  final playlistTracksMutex = Mutex();
  final playerTracksMutex = Mutex();

  List<MinimalTrack> _originalTracksPlaylist = [];

  final List<MinimalTrack> _previousTracks = [];

  final List<MinimalTrack> _queueTracks = [];

  final List<MinimalTrack> _nextTracks = [];

  bool isShuffled = false;

  // ignore: unused_element
  void _debugTracks() {
    // ignore: avoid_print
    print("PREV ------------------------");

    for (final (index, track) in _previousTracks.indexed) {
      // ignore: avoid_print
      print("$index : ${track.title}");
    }

    // ignore: avoid_print
    print("QUEUE ------------------------");

    for (final (index, track) in _queueTracks.indexed) {
      // ignore: avoid_print
      print("$index : ${track.title}");
    }

    // ignore: avoid_print
    print("NEXT ------------------------");

    for (final (index, track) in _nextTracks.indexed) {
      // ignore: avoid_print
      print("$index : ${track.title}");
    }

    // ignore: avoid_print
    print("\n---------------------------------------------\n");
  }

  @override
  Future<void> play() async {
    await api.play();

    await _updatePlaybackState();
  }

  @override
  Future<void> pause() async {
    await api.pause();

    await _updatePlaybackState();
  }

  @override
  Future<void> stop() async {
    await api.pause();

    await _updatePlaybackState();
  }

  @override
  Future<void> seek(Duration position) async {
    await api.seek(position.inMilliseconds);

    await _updatePlaybackState();
  }

  @override
  Future<void> skipToPrevious() async {
    await api.skipToPrevious();

    await api.play();

    await _updatePlaybackState();
  }

  @override
  Future<void> skipToNext() async {
    await api.skipToNext();

    await api.play();

    await _updatePlaybackState();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _updatePlaylistTracks(index);

    await api.play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await api.setLoopMode(const {
      AudioServiceRepeatMode.none: MelodinkHostPlayerLoopMode.none,
      AudioServiceRepeatMode.all: MelodinkHostPlayerLoopMode.all,
      AudioServiceRepeatMode.one: MelodinkHostPlayerLoopMode.one,
    }[repeatMode]!);

    await _updatePlaybackState();
  }

  Future<void> toogleShufle() async {
    if (playbackState.value.shuffleMode == AudioServiceShuffleMode.all) {
      await setShuffleMode(AudioServiceShuffleMode.none);
    } else {
      await setShuffleMode(AudioServiceShuffleMode.all);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await playlistTracksMutex.protect(() async {
      await _doShuffle(shuffleMode);
    });
  }

  Future<void> loadTracks(
    List<MinimalTrack> tracks, {
    int startAt = -1,
    bool restart = true,
  }) async {
    await playlistTracksMutex.protect(() async {
      _originalTracksPlaylist = List.from(tracks);

      _previousTracks.clear();
      _nextTracks.clear();

      if (tracks.isEmpty) {
        return;
      }

      for (var i = 0; i <= startAt; i++) {
        _previousTracks.add(tracks[i]);
      }

      _nextTracks.addAll(tracks.sublist(startAt + 1));

      if (isShuffled) {
        await _doShuffle(AudioServiceShuffleMode.all);
      }

      if (_previousTracks.isEmpty && _nextTracks.isNotEmpty) {
        _previousTracks.add(_nextTracks.removeAt(0));
      }

      await _updatePlayerTracks();

      if (restart) {
        await seek(Duration.zero);

        await api.play();
      }

      await _updatePlaybackState();
    });
  }

  Future<void> addTrackToQueue(MinimalTrack track) async {
    await playlistTracksMutex.protect(() async {
      _queueTracks.add(track);

      if (_previousTracks.isEmpty && _queueTracks.isNotEmpty) {
        _previousTracks.add(_queueTracks.removeAt(0));
      }

      await _updatePlayerTracks();

      await _updatePlaybackState();
    });
  }

  Future<void> setQueueAndNext(
    List<MinimalTrack> queueTracks,
    List<MinimalTrack> nextTracks,
  ) async {
    await playlistTracksMutex.protect(() async {
      _queueTracks.clear();
      _nextTracks.clear();

      _queueTracks.addAll(queueTracks);
      _nextTracks.addAll(nextTracks);

      await _updatePlayerTracks();

      await _updatePlaybackState();
    });
  }

  Future<void> _doShuffle(AudioServiceShuffleMode shuffleMode) async {
    final currentTrack = _previousTracks.lastOrNull;

    _previousTracks.clear();
    _nextTracks.clear();

    final newPlaylist = List.from(_originalTracksPlaylist);

    if (shuffleMode == AudioServiceShuffleMode.all) {
      newPlaylist.shuffle();
      isShuffled = true;

      for (var i = 0; i < newPlaylist.length; i++) {
        final track = newPlaylist[i];

        if (track.id == currentTrack?.id) {
          _previousTracks.add(track);
        } else {
          _nextTracks.add(track);
        }
      }
    } else {
      isShuffled = false;

      bool putInNext = false;
      for (var i = 0; i < newPlaylist.length; i++) {
        final track = newPlaylist[i];

        if (!putInNext) {
          _previousTracks.add(track);
        } else {
          _nextTracks.add(track);
        }

        if (track.id == currentTrack?.id) {
          putInNext = true;
        }
      }

      // The current track is from the queue
      if (!putInNext && currentTrack != null) {
        _nextTracks.addAll(_previousTracks);
        _previousTracks.clear();
        _previousTracks.add(currentTrack);
      }
    }

    if (_previousTracks.isEmpty) {
      // The current track is from the queue
      if (currentTrack != null) {
        _previousTracks.add(currentTrack);
      } else if (_nextTracks.isNotEmpty) {
        _previousTracks.add(_nextTracks.removeAt(0));
      }
    }

    if (!(_previousTracks.isEmpty &&
        _nextTracks.isEmpty &&
        _queueTracks.isEmpty)) {
      await _updatePlayerTracks();
    }

    await _updatePlaybackState();
  }

  Future<void> _updatePlaylistTracks(int currentTrackIndex) async {
    await playlistTracksMutex.protect(() async {
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

      await _updatePlayerTracks();

      await _updatePlaybackState();
    });
  }

  Future<void> _updatePlayerTracks() async {
    await playerTracksMutex.protect(() async {
      await api.setAuthToken(
        await AppApi().generateCookieHeader(),
      );

      await api.setAudios(
        _previousTracks.map((track) => track.getUrl()).toList(),
        [..._queueTracks, ..._nextTracks]
            .map((track) => track.getUrl())
            .toList(),
      );

      await updateQueue([..._previousTracks, ..._queueTracks, ..._nextTracks]
          .map((track) => MediaItem(
                id: "${track.id}",
                album: track.album,
                title: track.title,
                artist: track.albumArtist,
                duration: track.duration,
                artUri: Uri.parse(track.getCoverUrl()),
              ))
          .toList());
    });
  }

  @override
  Future<void> audioChanged(int pos) async {
    await _updatePlaylistTracks(pos);
  }

  @override
  Future<void> updateState(MelodinkHostPlayerProcessingState state) async {
    playbackState.add(playbackState.value.copyWith(
      processingState: const {
        MelodinkHostPlayerProcessingState.idle: AudioProcessingState.idle,
        MelodinkHostPlayerProcessingState.loading: AudioProcessingState.loading,
        MelodinkHostPlayerProcessingState.buffering:
            AudioProcessingState.buffering,
        MelodinkHostPlayerProcessingState.ready: AudioProcessingState.ready,
        MelodinkHostPlayerProcessingState.completed:
            AudioProcessingState.completed,
      }[state]!,
    ));
  }

  Future<void> _updatePlaybackState() async {
    final status = await api.fetchStatus();

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (status.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        MelodinkHostPlayerProcessingState.idle: AudioProcessingState.idle,
        MelodinkHostPlayerProcessingState.loading: AudioProcessingState.loading,
        MelodinkHostPlayerProcessingState.buffering:
            AudioProcessingState.buffering,
        MelodinkHostPlayerProcessingState.ready: AudioProcessingState.ready,
        MelodinkHostPlayerProcessingState.completed:
            AudioProcessingState.completed,
      }[status.state]!,
      playing: status.playing,
      updatePosition: Duration(milliseconds: status.positionMs),
      bufferedPosition: Duration(milliseconds: status.bufferedPositionMs),
      speed: 1.0,
      repeatMode: const {
        MelodinkHostPlayerLoopMode.none: AudioServiceRepeatMode.none,
        MelodinkHostPlayerLoopMode.all: AudioServiceRepeatMode.all,
        MelodinkHostPlayerLoopMode.one: AudioServiceRepeatMode.one,
      }[status.loop]!,
      queueIndex: status.pos,
      shuffleMode: isShuffled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    ));

    _updateUiTrackLists();
  }

  final BehaviorSubject<List<MinimalTrack>> previousTracks =
      BehaviorSubject.seeded([]);

  final BehaviorSubject<List<MinimalTrack>> queueTracks =
      BehaviorSubject.seeded([]);

  final BehaviorSubject<List<MinimalTrack>> nextTracks =
      BehaviorSubject.seeded([]);

  final BehaviorSubject<MinimalTrack?> currentTrack =
      BehaviorSubject.seeded(null);

  void _updateUiTrackLists() {
    previousTracks.add(List.from(_previousTracks));

    queueTracks.add(List.from(_queueTracks));

    nextTracks.add(List.from(_nextTracks));

    currentTrack.add(_previousTracks.lastOrNull);
  }
}

final audioControllerProvider = Provider((ref) => _audioController);
