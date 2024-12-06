import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/helpers/debounce.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/player/domain/audio/melodink_player.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';
import 'package:melodink_client/generated/messages.g.dart';
import 'package:mutex/mutex.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  await _audioController.restoreLastState();

  return _audioController;
}

class AudioController extends BaseAudioHandler
    implements MelodinkHostPlayerApiInfo {
  static final Stream<Duration> quickPosition =
      AudioService.createPositionStream(
          steps: 8000,
          minPeriod: const Duration(milliseconds: 16),
          maxPeriod: const Duration(milliseconds: 200));

  AudioController() {
    player.eventAudioChangedStream.listen((value) {
      audioChanged(value);
    });

    player.eventUpdateStateStream.listen((value) {
      updateState(value);
    });

    Connectivity().onConnectivityChanged.listen((_) {
      reloadPlayerTracks();
    });
  }

  final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

  final player = MelodinkPlayer();

  DownloadTrackRepository? downloadTrackRepository;

  PlayerTrackerManager? playerTrackerManager;

  final playlistTracksMutex = Mutex();
  final playerTracksMutex = Mutex();

  List<MinimalTrack> _originalTracksPlaylist = [];

  final List<MinimalTrack> _previousTracks = [];

  final List<MinimalTrack> _queueTracks = [];

  final List<MinimalTrack> _nextTracks = [];

  bool isShuffled = false;

  bool _isPlayerTracksEmpty() {
    return _previousTracks.isEmpty &&
        _queueTracks.isEmpty &&
        _nextTracks.isEmpty;
  }

  // ignore: unused_element
  void _debugTracks() {
    audioControllerLogger.d("PREV ------------------------");

    for (final (index, track) in _previousTracks.indexed) {
      audioControllerLogger.d("$index : ${track.title}");
    }

    audioControllerLogger.d("QUEUE ------------------------");

    for (final (index, track) in _queueTracks.indexed) {
      audioControllerLogger.d("$index : ${track.title}");
    }

    audioControllerLogger.d("NEXT ------------------------");

    for (final (index, track) in _nextTracks.indexed) {
      audioControllerLogger.d("$index : ${track.title}");
    }

    audioControllerLogger
        .d("\n---------------------------------------------\n");
  }

  Future<void> restoreLastState() async {
    final config = await SettingsRepository().getSettings();

    if (config.rememberLoopAndShuffleAcrossRestarts) {
      final rawLastShuffleState = await _asyncPrefs.getString(
        "audioPlayerLastShuffleState",
      );

      final rawLastLoopState = await _asyncPrefs.getString(
        "audioPlayerLastLoopState",
      );

      AudioServiceShuffleMode? lastShuffleMode;
      AudioServiceRepeatMode? lastLoopMode;

      if (rawLastShuffleState != null) {
        lastShuffleMode = AudioServiceShuffleMode.values
            .where((value) => value.name == rawLastShuffleState)
            .firstOrNull;
      }

      if (rawLastLoopState != null) {
        lastLoopMode = AudioServiceRepeatMode.values
            .where((value) => value.name == rawLastLoopState)
            .firstOrNull;
      }

      if (lastShuffleMode != null) {
        await setShuffleMode(lastShuffleMode);
      }

      if (lastLoopMode != null) {
        await setRepeatMode(lastLoopMode);
      }
    }
  }

  @override
  Future<void> play() async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    if (playbackState.valueOrNull?.processingState ==
        AudioProcessingState.completed) {
      await skipToQueueItem(0);

      player.seek(0);
    } else if (playbackState.valueOrNull?.processingState ==
        AudioProcessingState.error) {
      await skipToQueueItem(_previousTracks.length - 1);

      player.seek(0);
    }

    player.play();

    await _updatePlaybackState();
  }

  @override
  Future<void> pause() async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    player.pause();

    await _updatePlaybackState();
  }

  @override
  Future<void> stop() async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    player.pause();

    await _updatePlaybackState();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    player.seek(position.inMilliseconds);

    player.play();

    await _updatePlaybackState();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    if (_previousTracks.length == 1) {
      player.seek(0);
    } else if (playbackState.value.position.inMilliseconds > 5000) {
      player.seek(0);
    } else {
      player.skipToPrevious();
    }

    player.play();
  }

  @override
  Future<void> skipToNext() async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    player.skipToNext();

    player.play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    await _updatePlaylistTracks(index);

    player.play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    player.setLoopMode(const {
      AudioServiceRepeatMode.none: MelodinkLoopMode.none,
      AudioServiceRepeatMode.all: MelodinkLoopMode.all,
      AudioServiceRepeatMode.one: MelodinkLoopMode.one,
    }[repeatMode]!);

    await _updatePlaylistTracks(_previousTracks.length - 1);

    await _asyncPrefs.setString(
      "audioPlayerLastLoopState",
      repeatMode.name,
    );
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

  setVolume(double volume) {
    player.setVolume(volume.clamp(0, 100) / 100.0);
  }

  double getVolume() {
    return (player.getVolume() * 100.0).clamp(0, 100);
  }

  Future<void> loadTracks(
    List<MinimalTrack> tracks, {
    int startAt = -1,
    bool restart = true,
    String? source,
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
        await _doShuffle(
          AudioServiceShuffleMode.all,
          shouldUpdatePlayersTracks: false,
        );
      }

      if (_previousTracks.isEmpty && _nextTracks.isNotEmpty) {
        _previousTracks.add(_nextTracks.removeAt(0));
      }

      await _updatePlayerTracks();

      if (restart) {
        await seek(Duration.zero);

        player.play();
      }

      playerTracksFrom.add(source);

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

  Future<void> addTracksToQueue(List<MinimalTrack> tracks) async {
    await playlistTracksMutex.protect(() async {
      _queueTracks.addAll(tracks);

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

  Future<void> clean() async {
    await playlistTracksMutex.protect(() async {
      player.pause();

      await _updatePlayerTracks();
      await _updatePlaybackState();

      playerTracksFrom.add(null);
      _previousTracks.clear();
      _nextTracks.clear();
      _queueTracks.clear();

      await _updatePlayerTracks();
      await _updatePlaybackState();
    });
  }

  Future<void> _doShuffle(
    AudioServiceShuffleMode shuffleMode, {
    bool shouldUpdatePlayersTracks = true,
  }) async {
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

    if (shouldUpdatePlayersTracks) {
      if (!(_previousTracks.isEmpty &&
          _nextTracks.isEmpty &&
          _queueTracks.isEmpty)) {
        await _updatePlayerTracks();
      }

      await _updatePlaybackState();
    }

    await _asyncPrefs.setString(
      "audioPlayerLastShuffleState",
      shuffleMode.name,
    );
  }

  Future<void> _updatePlaylistTracks(int currentTrackIndex,
      {bool updatePlayerTracks = true}) async {
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

      if (updatePlayerTracks) {
        await _updatePlayerTracks();
      }

      await _updatePlaybackState();
    });
  }

  int? _lastCurrentTrackId;
  String? _lastCurrentTrackUrl;

  DateTime _lastUpdatePlayerTracks = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _updatePlayerTracks() async {
    await playerTracksMutex.protect(() async {
      if (DateTime.now().difference(_lastUpdatePlayerTracks).inMilliseconds <
          10) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      _lastUpdatePlayerTracks = DateTime.now();

      player.setAuthToken(
        AppApi().generateCookieHeader(),
      );

      // AudioQuality
      final config = await SettingsRepository().getSettings();

      final connectivityResult = await (Connectivity().checkConnectivity());

      AppSettingAudioQuality currentAudioQuality = config.cellularAudioQuality;

      if (connectivityResult.contains(ConnectivityResult.ethernet) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        currentAudioQuality = config.wifiAudioQuality;
      }

      final getDownloadedTrackByTrackId =
          downloadTrackRepository?.getDownloadedTrackByTrackId;

      final List<String> prevUrls = [];

      for (final (index, track) in _previousTracks.indexed) {
        if (index == _previousTracks.length - 1) {
          if (_lastCurrentTrackId == track.id) {
            prevUrls
                .add(_lastCurrentTrackUrl ?? track.getUrl(currentAudioQuality));
            continue;
          }
        }

        DownloadTrack? downloadedTrack;

        if (index >= _previousTracks.length - 15 &&
            getDownloadedTrackByTrackId != null) {
          downloadedTrack = await getDownloadedTrackByTrackId(track.id);
        }

        late String url;

        if (downloadedTrack == null) {
          url = track.getUrl(currentAudioQuality);
        } else {
          url = downloadedTrack.getUrl();
        }

        prevUrls.add(url);

        if (index == _previousTracks.length - 1) {
          _lastCurrentTrackId = track.id;
          _lastCurrentTrackUrl = url;
        }
      }

      final List<String> nextUrls = [];

      for (final (index, track) in [..._queueTracks, ..._nextTracks].indexed) {
        DownloadTrack? downloadedTrack;

        if (index <= 15 && getDownloadedTrackByTrackId != null) {
          downloadedTrack = await getDownloadedTrackByTrackId(track.id);
        }

        if (downloadedTrack == null) {
          nextUrls.add(track.getUrl(currentAudioQuality));
        } else {
          nextUrls.add(downloadedTrack.getUrl());
        }
      }

      Map<String, int> urlCount = {};

      final List<String> uniquePreviousUrls = [];
      final List<String> uniqueNextUrls = [];

      void addUrl(String url, List<String> list, List<String> output) {
        if (urlCount.containsKey(url)) {
          urlCount[url] = urlCount[url]! + 1;
        } else {
          urlCount[url] = 1;
        }
        output.add('$url?i=${urlCount[url]}');
      }

      for (String url in prevUrls) {
        addUrl(url, prevUrls, uniquePreviousUrls);
      }

      for (String url in nextUrls) {
        addUrl(url, nextUrls, uniqueNextUrls);
      }

      if (prevUrls.isNotEmpty) {
        player.setAudios(
          uniquePreviousUrls,
          uniqueNextUrls,
        );
      }
    });
  }

  Future<void> reloadPlayerTracks() async {
    if (_previousTracks.isEmpty &&
        _queueTracks.isEmpty &&
        _nextTracks.isEmpty) {
      return;
    }

    await _updatePlayerTracks();

    await _updatePlaybackState();
  }

  final audioChangedDebouncer = Debouncer(milliseconds: 50);

  void audioChanged(int pos) {
    audioChangedDebouncer.run(() async {
      if (pos != _previousTracks.length - 1) {
        await _updatePlaylistTracks(pos);
      }
    });
  }

  void updateState(MelodinkProcessingState state) {
    audioChangedDebouncer.run(() async {
      if (_previousTracks.isEmpty) {
        return;
      }

      final pos = player.getCurrentTrackPos();

      await _updatePlaylistTracks(
        pos,
        updatePlayerTracks: pos != _previousTracks.length - 1,
      );
    });
  }

  @override
  Future<void> externalPause() async {
    await pause();
  }

  Future<void> _updatePlaybackState() async {
    _updateUiTrackLists();

    final playerPlaying = player.getCurrentPlaying();
    final playerState = player.getCurrentPlayerState();
    final playerPositionMs = player.getCurrentPosition();
    final playerBufferedPositionMs = player.getCurrentBufferedPosition();
    final playerLoop = player.getCurrentLoopMode();

    final newState = playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playerPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        MelodinkProcessingState.idle: AudioProcessingState.idle,
        MelodinkProcessingState.loading: AudioProcessingState.loading,
        MelodinkProcessingState.buffering: AudioProcessingState.buffering,
        MelodinkProcessingState.ready: AudioProcessingState.ready,
        MelodinkProcessingState.completed: AudioProcessingState.completed,
        MelodinkProcessingState.error: AudioProcessingState.error,
      }[playerState]!,
      playing:
          playerState == MelodinkProcessingState.idle || _previousTracks.isEmpty
              ? false
              : playerPlaying,
      updatePosition: Duration(milliseconds: playerPositionMs),
      bufferedPosition: Duration(milliseconds: playerBufferedPositionMs),
      speed: 1.0,
      repeatMode: const {
        MelodinkLoopMode.none: AudioServiceRepeatMode.none,
        MelodinkLoopMode.all: AudioServiceRepeatMode.all,
        MelodinkLoopMode.one: AudioServiceRepeatMode.one,
      }[playerLoop]!,
      queueIndex: _previousTracks.lastOrNull?.id,
      shuffleMode: isShuffled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );

    playerTrackerManager?.watchState(
      playbackState.value,
      newState,
      _previousTracks.lastOrNull,
    );

    playbackState.add(newState);

    final track = _previousTracks.lastOrNull;

    final getDownloadedTrackByTrackId =
        downloadTrackRepository?.getDownloadedTrackByTrackId;

    DownloadTrack? downloadedTrack;

    if (getDownloadedTrackByTrackId != null && track != null) {
      downloadedTrack = await getDownloadedTrackByTrackId(track.id);
    }

    mediaItem.add(track != null
        ? MediaItem(
            id: "${track.id}",
            album: track.album,
            title: track.title,
            artist: track.artists.map((artist) => artist.name).join(", "),
            duration: track.duration,
            artUri: downloadedTrack?.getCoverUri() ??
                track.getCompressedCoverUri(
                  TrackCompressedCoverQuality.medium,
                ),
            artHeaders: {
              'Cookie': AppApi().generateCookieHeader(),
            },
          )
        : null);

    // Fix tiny wrong start delay
    Future.delayed(const Duration(milliseconds: 200)).then(
      (_) => _updateTinyCurrentPosition(),
    );
  }

  Future<void> _updateTinyCurrentPosition() async {
    final positionMs = player.getCurrentPosition();
    final bufferedPositionMs = player.getCurrentBufferedPosition();

    final newState = playbackState.value.copyWith(
      updatePosition: Duration(milliseconds: positionMs),
      bufferedPosition: Duration(milliseconds: bufferedPositionMs),
    );

    playerTrackerManager?.watchState(
      playbackState.value,
      newState,
      _previousTracks.lastOrNull,
    );

    playbackState.add(newState);
  }

  final BehaviorSubject<List<MinimalTrack>> previousTracks =
      BehaviorSubject.seeded([]);

  final BehaviorSubject<List<MinimalTrack>> queueTracks =
      BehaviorSubject.seeded([]);

  final BehaviorSubject<List<MinimalTrack>> nextTracks =
      BehaviorSubject.seeded([]);

  final BehaviorSubject<MinimalTrack?> currentTrack =
      BehaviorSubject.seeded(null);

  final BehaviorSubject<String?> playerTracksFrom =
      BehaviorSubject.seeded(null);

  void _updateUiTrackLists() {
    previousTracks.add(List.from(_previousTracks));

    queueTracks.add(List.from(_queueTracks));

    nextTracks.add(List.from(_nextTracks));

    currentTrack.add(_previousTracks.lastOrNull);
  }
}

final audioControllerProvider = Provider((ref) {
  _audioController.downloadTrackRepository =
      ref.watch(downloadTrackRepositoryProvider);

  _audioController.playerTrackerManager =
      ref.watch(playerTrackerManagerProvider);

  return _audioController;
});
