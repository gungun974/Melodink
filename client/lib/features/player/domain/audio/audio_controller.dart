import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/helpers/debounce.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/player/domain/audio/melodink_player.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/edit_track_provider.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final AudioController _audioController;
final AudioSessionHandler _audioSessionHandler = AudioSessionHandler();

Future<AudioController> initAudioService() async {
  _audioController = await AudioService.init(
    builder: () => AudioController(),
    config: const AudioServiceConfig(
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidNotificationChannelName: 'Melodink Audio Service',
      androidNotificationChannelId: 'fr.gungun974.melodink.audio',
      androidNotificationChannelDescription: 'Melodink Media Controls',
    ),
  );

  await _audioSessionHandler.initSession();

  await _audioController.restoreLastState();

  return _audioController;
}

class AudioController extends BaseAudioHandler {
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

      await player.seek(0);
    } else if (playbackState.valueOrNull?.processingState ==
        AudioProcessingState.error) {
      await skipToQueueItem(_previousTracks.length - 1);

      await player.seek(0);
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
    if (Platform.isAndroid) {
      return;
    }
    return pause();
  }

  @override
  Future<void> onTaskRemoved() async {
    await pause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    await player.seek(position.inMicroseconds / 1000000);

    player.play();

    await _updatePlaybackState();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    if (_previousTracks.length == 1) {
      await player.seek(0);
    } else if (playbackState.value.position.inMilliseconds > 5000) {
      await player.seek(0);
    } else {
      await player.skipToPrevious();
    }

    player.play();
  }

  @override
  Future<void> skipToNext() async {
    if (_isPlayerTracksEmpty()) {
      return;
    }

    await player.skipToNext();

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

  Future<void> clearQueue() async {
    await playlistTracksMutex.protect(() async {
      _queueTracks.clear();

      await _updatePlayerTracks();

      await _updatePlaybackState();
    });
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
    bool skipOffline = true,
  }) async {
    await playlistTracksMutex.protect(() async {
      final isServerRecheable = NetworkInfo().isServerRecheable();

      final isTrackDownloaded = downloadTrackRepository?.isTrackDownloaded;

      if (skipOffline && !isServerRecheable && isTrackDownloaded != null) {
        List<MinimalTrack> filteredTracks = [];
        int newStartAt = -1;

        for (int i = 0; i < tracks.length; i++) {
          MinimalTrack track = tracks[i];

          final isDownloaded = await isTrackDownloaded(track.id);

          if (isDownloaded) {
            filteredTracks.add(track);
          }

          if (i == startAt) {
            if (!isDownloaded && !filteredTracks.contains(track)) {
              filteredTracks.add(track);
            }
            newStartAt = filteredTracks.indexOf(track);
          }
        }

        startAt = newStartAt;
        tracks = filteredTracks;
      }

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
      final playerState = player.getCurrentPlayerState();

      bool shouldForcePlay = false;

      if (currentTrackIndex != 0 &&
          playerState == MelodinkProcessingState.completed &&
          !(currentTrackIndex == _previousTracks.length - 1 &&
              _nextTracks.isEmpty &&
              _queueTracks.isEmpty)) {
        currentTrackIndex += 1;
        updatePlayerTracks = true;
        shouldForcePlay = true;
      }

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

      if (shouldForcePlay) {
        player.play();
      }

      await _updatePlaybackState();
    });
  }

  int? _lastCurrentTrackId;
  MelodinkTrackRequest? _lastCurrentTrackRequest;

  DateTime _lastUpdatePlayerTracks = DateTime.fromMillisecondsSinceEpoch(0);

  updatePlayerQuality() async {
    // AudioQuality
    final config = await SettingsRepository().getSettings();

    final connectivityResult = await (Connectivity().checkConnectivity());

    AppSettingAudioQuality currentAudioQuality = config.cellularAudioQuality;

    if (connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      currentAudioQuality = config.wifiAudioQuality;
    }

    player.setQuality(currentAudioQuality);
  }

  Future<void> _updatePlayerTracks() async {
    return await playerTracksMutex.protect(() async {
      if (DateTime.now().difference(_lastUpdatePlayerTracks).inMilliseconds <
          10) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      _lastUpdatePlayerTracks = DateTime.now();

      await updatePlayerQuality();

      final getDownloadedTrackByTrackId =
          downloadTrackRepository?.getDownloadedTrackByTrackId;

      final List<MelodinkTrackRequest> requests = [];

      int currentRequestIndex = 0;

      for (final (index, track) in [
        ..._previousTracks,
        ..._queueTracks,
        ..._nextTracks,
      ].indexed) {
        if (index != 0 && index <= _previousTracks.length - 8) {
          continue;
        }

        if (index > _previousTracks.length + 10) {
          continue;
        }

        if (index == _previousTracks.length - 1) {
          if (_lastCurrentTrackId == track.id) {
            requests.add(
              _lastCurrentTrackRequest ??
                  MelodinkTrackRequest(
                    id: track.id,
                    originalAudioHash: track.fileSignature,
                    downloadedPath: "",
                  ),
            );
            currentRequestIndex = requests.length - 1;
            continue;
          }
        }

        DownloadTrack? downloadedTrack;

        if (getDownloadedTrackByTrackId != null) {
          downloadedTrack = await getDownloadedTrackByTrackId(
            track.id,
            shouldVerifyIfFileExist: true,
          );
        }

        late MelodinkTrackRequest request;

        if (downloadedTrack == null) {
          request = MelodinkTrackRequest(
            id: track.id,
            originalAudioHash: track.fileSignature,
            downloadedPath: "",
          );
        } else {
          request = MelodinkTrackRequest(
            id: track.id,
            originalAudioHash: track.fileSignature,
            downloadedPath: downloadedTrack.getUrl(),
          );
        }

        requests.add(request);

        if (index == _previousTracks.length - 1) {
          _lastCurrentTrackId = track.id;
          _lastCurrentTrackRequest = request;
          currentRequestIndex = requests.length - 1;
        }
      }

      if (requests.isNotEmpty) {
        await player.setAudios(
          AppApi().getServerUrl(),
          join((await getMelodinkInstanceCacheDirectory()).path, "audioCache"),
          _previousTracks.length - 1,
          currentRequestIndex,
          requests,
          AppApi().generateCookieHeader(),
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

  final audioChangedDebouncer = Debouncer(milliseconds: 5);

  void audioChanged(int pos) {
    audioChangedDebouncer.run(() async {
      await _updatePlaylistTracks(
        pos,
        updatePlayerTracks: true,
      );
    });
  }

  void updateState(MelodinkProcessingState state) {
    if (_previousTracks.isEmpty) {
      return;
    }

    _updatePlaybackState();
  }

  Future<void> _updatePlaybackState({shouldDoubleCheck = true}) async {
    _updateUiTrackLists();

    final playerPlaying = player.getCurrentPlaying();
    final playerState = player.getCurrentPlayerState();
    final playerPosition = player.getCurrentPosition();
    final playerBufferedPosition = player.getCurrentBufferedPosition();
    final playerLoop = player.getCurrentLoopMode();

    _audioSessionHandler.setActive(playerPlaying);

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
      updatePosition:
          Duration(microseconds: (playerPosition * 1000000).round()),
      bufferedPosition:
          Duration(microseconds: (playerBufferedPosition * 1000000).round()),
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

    // Be sure current Player State is up to date in case of strange lag
    if (shouldDoubleCheck) {
      Future.delayed(const Duration(milliseconds: 10)).then(
        (_) => _updatePlaybackState(shouldDoubleCheck: false),
      );
    }
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

  updateTrack(Track newTrack) async {
    await playlistTracksMutex.protect(() async {
      for (final entry in _previousTracks.indexed) {
        if (entry.$2.id == newTrack.id) {
          _previousTracks[entry.$1] = newTrack.toMinimalTrack();
        }
      }

      for (final entry in _queueTracks.indexed) {
        if (entry.$2.id == newTrack.id) {
          _queueTracks[entry.$1] = newTrack.toMinimalTrack();
        }
      }

      for (final entry in _nextTracks.indexed) {
        if (entry.$2.id == newTrack.id) {
          _nextTracks[entry.$1] = newTrack.toMinimalTrack();
        }
      }

      _updateUiTrackLists();
    });
  }
}

final audioControllerProvider = Provider((ref) {
  _audioController.downloadTrackRepository =
      ref.watch(downloadTrackRepositoryProvider);

  _audioController.playerTrackerManager =
      ref.watch(playerTrackerManagerProvider);

  ref.listen(trackEditStreamProvider, (_, rawNewTrack) async {
    final newTrack = rawNewTrack.valueOrNull?.track;

    if (newTrack == null) {
      return;
    }

    await _audioController.updateTrack(newTrack);
  });

  return _audioController;
});

class AudioSessionHandler {
  late AudioSession session;
  bool _playInterrupted = false;

  setActive(bool active) {
    // Miniaudio handle IOS
    if (Platform.isIOS) {
      return;
    }
    session.setActive(active);
  }

  AudioSessionHandler() {
    initSession();
  }

  Future<void> initSession() async {
    session = await AudioSession.instance;
    session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (!_audioController.playbackState.value.playing) return;
        switch (event.type) {
          case AudioInterruptionType.duck:
            _audioController.setVolume(_audioController.getVolume() * 0.5);
            break;
          case AudioInterruptionType.pause:
            _audioController.pause();
            _playInterrupted = true;
            break;
          case AudioInterruptionType.unknown:
            _audioController.pause();
            _playInterrupted = true;
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _audioController.setVolume(_audioController.getVolume() * 2);
            break;
          case AudioInterruptionType.pause:
            if (_playInterrupted) _audioController.play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
        _playInterrupted = false;
      }
    });

    session.becomingNoisyEventStream.listen((_) {
      if (_audioController.playbackState.value.playing) {
        _audioController.pause();
      }
    });
  }
}
