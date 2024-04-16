import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melodink_client/core/helpers/debouncer.dart';
import 'package:melodink_client/core/helpers/generate_unique_id.dart';
import 'package:mutex/mutex.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Melodink Audio Service',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

const numberOfPreloadTrack = 15;

class MyAudioHandler extends BaseAudioHandler {
  late final _player = AudioPlayer();

  final _playlist = ConcatenatingAudioSource(
    useLazyPreparation: true,
    children: [],
  );

  MyAudioHandler() {
    _loadEmptyPlaylist();

    _notifyAudioHandlerAboutPlaybackEvents();

    _listenForDurationChanges();

    _listenForCurrentSongIndexChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(
        _playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await _player.stop();
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    final newQueue = queue
        .map(
          (mediaItem) => MediaItem(
            id: mediaItem.id,
            title: mediaItem.title,
            album: mediaItem.album,
            artist: mediaItem.artist,
            genre: mediaItem.genre,
            duration: mediaItem.duration,
            artUri: mediaItem.artUri,
            artHeaders: mediaItem.artHeaders,
            playable: mediaItem.playable,
            displayTitle: mediaItem.displayTitle,
            displaySubtitle: mediaItem.displaySubtitle,
            displayDescription: mediaItem.displayDescription,
            rating: mediaItem.rating,
            extras: {
              ...(mediaItem.extras ?? {}),
              "index": mediaItem.extras?.containsKey("index") == true
                  ? mediaItem.extras!["index"]
                  : generateUniqueID(),
            },
          ),
        )
        .toList();

    this.queue.add(newQueue);

    _updateLazyLoad();
  }

  int? _getCurrentTrackIndex() {
    final currentPlayerIndex = _player.currentIndex;

    if (currentPlayerIndex == null) {
      return null;
    }

    if (currentPlayerIndex < 0 || currentPlayerIndex >= _playlist.length) {
      return null;
    }

    final currentAudio = _playlist[currentPlayerIndex];

    if (currentAudio is! IndexedAudioSource) {
      return null;
    }

    final mediaItem = currentAudio.tag;

    if (mediaItem is! MediaItem) {
      return null;
    }

    final trackIndex = queue.value.indexWhere(
        (track) => track.extras?["index"] == mediaItem.extras?["index"]);

    if (trackIndex < 0) {
      return null;
    }

    return trackIndex;
  }

  final m = Mutex();

  Future<void> _updateLazyLoad({int? forceTrackIndex}) async {
    await m.protect(() async {
      final List<AudioSource> medias = [];

      // Wait at least 1ms to be sure playlist object is up to date
      await Future.delayed(const Duration(milliseconds: 1));

      int? trackIndex = _getCurrentTrackIndex();

      if (forceTrackIndex != null) {
        trackIndex = forceTrackIndex;
      }

      if (trackIndex == null) {
        return;
      }

      for (int j = 0; j < numberOfPreloadTrack - 1; j++) {
        if (trackIndex + j < 0 || trackIndex + j >= queue.value.length) {
          continue;
        }

        final currentMediaItem = queue.value[trackIndex + j];

        medias.add(_createAudioSource(currentMediaItem));
      }

      for (int j = 1; j < numberOfPreloadTrack - 1; j++) {
        if (trackIndex - j < 0 || trackIndex - j >= queue.value.length) {
          continue;
        }

        final currentMediaItem = queue.value[trackIndex - j];
        medias.insert(0, _createAudioSource(currentMediaItem));
      }

      if (_player.loopMode == LoopMode.all) {
        for (int i = 0; i < numberOfPreloadTrack - 1; i++) {
          if (i < 0 || i >= queue.value.length) {
            continue;
          }

          final currentMediaItem = queue.value[i];

          if (i < medias.length) {
            final mediaItem = medias[i];

            if (mediaItem is! IndexedAudioSource) {
              continue;
            }

            final tag = mediaItem.tag;

            if (tag is! MediaItem) {
              continue;
            }

            if (currentMediaItem.extras?["index"] == tag.extras?["index"]) {
              continue;
            }
          }

          medias.insert(i, _createAudioSource(currentMediaItem));
        }
      }

      try {
        final l = ListTransformer(playlist: _playlist, player: _player);
        await l.transform(medias);
      } catch (e) {
        print("List Transformer Error : $e");
      }

      notifyPlayerQueueUpdateDebouncer(() {
        playbackState.add(playbackState.value.copyWith(
          queueIndex: _getCurrentTrackIndex(),
        ));

        customEvent.add({
          "type": "trackIndex",
          "trackIndex": _getCurrentTrackIndex(),
        });
      });
    });
  }

  final notifyPlayerQueueUpdateDebouncer =
      Debouncer(delay: const Duration(milliseconds: 35));

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(
        "${mediaItem.extras!['url'] as String}?rn=${mediaItem.extras?["index"]}",
      ),
      tag: mediaItem,
    );
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.currentIndex == 0) {
      await _player.seek(const Duration());
      return;
    }

    await _player.seekToPrevious();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      default:
        return;
    }

    playbackState.add(playbackState.value.copyWith(
      repeatMode: repeatMode,
      updatePosition: _player.position,
    ));
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) {
      return;
    }

    await _updateLazyLoad(forceTrackIndex: index);

    for (int i = 0; i < _playlist.length; i++) {
      final mediaItem = _playlist[i];

      if (mediaItem is! IndexedAudioSource) {
        continue;
      }

      final tag = mediaItem.tag;

      if (tag is! MediaItem) {
        continue;
      }

      if (tag.extras?["index"] == queue.value[index].extras?["index"]) {
        await _player.seek(Duration.zero, index: i);
      }
    }
  }

  int? _lastCurrentTrackIndex;

  Future<void> _listenForCurrentSongIndexChanges() async {
    _player.currentIndexStream.listen((_) async {
      final currentTrackIndex = _getCurrentTrackIndex();

      if (_lastCurrentTrackIndex != currentTrackIndex) {
        await _updateLazyLoad();
      }

      _lastCurrentTrackIndex = currentTrackIndex;
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((_) => _refreshPlaybackState());
  }

  void _refreshPlaybackState() {
    final playing = _player.playing;

    AudioServiceRepeatMode repeatMode = AudioServiceRepeatMode.none;

    switch (_player.loopMode) {
      case LoopMode.off:
        repeatMode = AudioServiceRepeatMode.none;
        break;
      case LoopMode.all:
        repeatMode = AudioServiceRepeatMode.all;
        break;
      case LoopMode.one:
        repeatMode = AudioServiceRepeatMode.one;
        break;
    }

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      repeatMode: repeatMode,
    ));
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _getCurrentTrackIndex();
      final currentQueue = queue.value;
      if (index == null || currentQueue.isEmpty) return;
      final oldMediaItem = currentQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      mediaItem.add(newMediaItem);
    });
  }
}

class ListTransformer {
  ConcatenatingAudioSource playlist;

  AudioPlayer player;

  ListTransformer({required this.player, required this.playlist});

  bool isSameItem(AudioSource a, AudioSource b) {
    if (a is! IndexedAudioSource) {
      return false;
    }

    final mediaItemA = a.tag;

    if (mediaItemA is! MediaItem) {
      return false;
    }

    if (b is! IndexedAudioSource) {
      return false;
    }

    final mediaItemB = b.tag;

    if (mediaItemB is! MediaItem) {
      return false;
    }

    return mediaItemA.extras?["index"] == mediaItemB.extras?["index"];
  }

  Future<void> transform(List<AudioSource> target) async {
    // Wait at least 1ms to be sure playlist object is up to date
    await Future.delayed(const Duration(milliseconds: 1));

    outerloop:
    for (int i = playlist.length - 1; i >= 0; i--) {
      for (final targetTrack in target) {
        if (isSameItem(playlist[i], targetTrack)) {
          continue outerloop;
        }
      }
      await playlist.removeAt(i);
    }

    outerloop:
    for (final targetTrack in target) {
      for (int i = 0; i < playlist.length; i++) {
        final playlistItem = playlist[i];
        if (isSameItem(playlistItem, targetTrack)) {
          continue outerloop;
        }
      }
      await playlist.add(targetTrack);
    }

    for (int j = 0; j < target.length; j++) {
      for (int i = 0; i < playlist.length; i++) {
        if (isSameItem(playlist[i], target[j])) {
          if (i != j) {
            await playlist.move(i, j);
            break;
          }
        }
      }
    }

    // Wait at least 1ms to be sure playlist object is up to date
    await Future.delayed(const Duration(milliseconds: 1));
  }
}
