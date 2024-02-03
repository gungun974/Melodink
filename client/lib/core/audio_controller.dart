import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

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

const numberOfPreloadTrack = 50;

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  MyAudioHandler() {
    _loadEmptyPlaylist();

    _notifyAudioHandlerAboutPlaybackEvents();

    _listenForDurationChanges();

    _listenForCurrentSongIndexChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  int lastIndex = 0;

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final newQueue = queue.value
      ..add(
        MediaItem(
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
            "index": lastIndex++,
          },
        ),
      );
    queue.add(newQueue);

    final trackIndexFromPlayer = getTrackIndexFromPlayer();
    if (trackIndexFromPlayer != null) {
      await preloadPlaylistToIndex(trackIndexFromPlayer);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final newQueue = queue.value
      ..addAll(
        mediaItems
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
                  "index": lastIndex++,
                },
              ),
            )
            .toList(),
      );
    queue.add(newQueue);

    final trackIndexFromPlayer = getTrackIndexFromPlayer();
    if (trackIndexFromPlayer != null) {
      await preloadPlaylistToIndex(trackIndexFromPlayer);
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    final newQueue = queue.value
      ..insert(
        index,
        MediaItem(
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
            "index": lastIndex++,
          },
        ),
      );
    queue.add(newQueue);

    final trackIndexFromPlayer = getTrackIndexFromPlayer();
    if (trackIndexFromPlayer != null) {
      await preloadPlaylistToIndex(trackIndexFromPlayer);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    try {
      await _listenForCurrentSongIndexChangesStream?.cancel();

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
                "index": lastIndex++,
              },
            ),
          )
          .toList();

      this.queue.add(newQueue);

      final trackIndexFromPlayer = getTrackIndexFromPlayer();
      if (trackIndexFromPlayer != null) {
        await preloadPlaylistToIndex(trackIndexFromPlayer);
      }
    } finally {
      await Future(() {});
      await _listenForCurrentSongIndexChanges();
    }
  }

  int? getTrackIndexFromPlayer() {
    final currentIndex = _player.currentIndex;

    if (currentIndex == null) {
      return null;
    }

    if (currentIndex >= _playlist.length) {
      return null;
    }

    final source = _playlist[currentIndex];

    if (source is! IndexedAudioSource) {
      return null;
    }

    final mediaItem = source.tag;

    if (mediaItem is! MediaItem) {
      return null;
    }

    final uniqueIndex = mediaItem.extras?["index"];

    if (uniqueIndex == null) {
      return null;
    }

    final index = queue.value
        .indexWhere((media) => media.extras?["index"] == uniqueIndex);

    if (index < 0) {
      return null;
    }

    return index;
  }

  int realCurrentTrackIndex = 0;

  preloadPlaylistToIndex(int trackIndex) async {
    realCurrentTrackIndex = trackIndex;

    int k = -1;
    for (int j = 0; j < numberOfPreloadTrack - 1; j++) {
      if (trackIndex + j < 0 || trackIndex + j >= queue.value.length) {
        continue;
      }

      final currentMediaItem = queue.value[trackIndex + j];
      k++;

      final i = (_player.currentIndex ?? 0) + k;

      if (i >= _playlist.length) {
        await _playlist.add(_createAudioSource(currentMediaItem));
      }

      final playlistTrack = _playlist[i];

      if (playlistTrack is! IndexedAudioSource) {
        await _playlist.removeAt(i);
        await _playlist.insert(
          i,
          _createAudioSource(currentMediaItem),
        );
        continue;
      }

      final tag = playlistTrack.tag;

      if (tag is! MediaItem) {
        await _playlist.removeAt(i);
        await _playlist.insert(
          i,
          _createAudioSource(currentMediaItem),
        );
        continue;
      }

      if (tag.extras?["index"] != currentMediaItem.extras?["index"]) {
        await _playlist.removeAt(i);
        await _playlist.insert(
          i,
          _createAudioSource(currentMediaItem),
        );
        continue;
      }
    }

    k = 0;
    for (int j = 1; j < numberOfPreloadTrack - 1; j++) {
      if (trackIndex - j < 0 || trackIndex - j >= queue.value.length) {
        continue;
      }

      final currentMediaItem = queue.value[trackIndex - j];
      k++;

      final i = (_player.currentIndex ?? 0) - k;

      if (i < 0) {
        await _playlist.insert(0, _createAudioSource(currentMediaItem));
        continue;
      }
    }
  }

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(mediaItem.extras!['url'] as String),
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
  Future<void> seek(Duration position) async {
    final isPlaying = _player.playing;
    await _player.seek(position);
    if (!isPlaying) {
      await _player.pause();
      await _player.pause();
    }
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) {
      return;
    }

    try {
      await _listenForCurrentSongIndexChangesStream?.cancel();

      await _playlist.clear();

      await preloadPlaylistToIndex(index);

      for (int i = 0; i < _playlist.length; i++) {
        final source = _playlist[i];

        if (source is! IndexedAudioSource) {
          continue;
        }

        final mediaItem = source.tag;

        if (mediaItem is! MediaItem) {
          continue;
        }

        if (mediaItem.extras?["index"] == queue.value[index].extras?["index"]) {
          await _player.seek(Duration.zero, index: i);
        }
      }
      _refreshPlaybackState();
    } finally {
      await Future(() {});
      await _listenForCurrentSongIndexChanges();
    }
  }

  StreamSubscription? _listenForCurrentSongIndexChangesStream;

  Future<void> _listenForCurrentSongIndexChanges() async {
    await _listenForCurrentSongIndexChangesStream?.cancel();

    _listenForCurrentSongIndexChangesStream =
        _player.currentIndexStream.listen((advertisedIndex) async {
      if (advertisedIndex == null) {
        return;
      }

      final trackIndexFromPlayer = getTrackIndexFromPlayer();
      if (trackIndexFromPlayer != null) {
        await preloadPlaylistToIndex(trackIndexFromPlayer);
      }
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((_) => _refreshPlaybackState());
  }

  void _refreshPlaybackState() {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 3],
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
      queueIndex: realCurrentTrackIndex,
    ));
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = realCurrentTrackIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }
}
