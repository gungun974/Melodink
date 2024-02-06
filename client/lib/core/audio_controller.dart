import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
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

const numberOfPreloadTrack = 50;

class MyAudioHandler extends BaseAudioHandler {
  late final _player = Player();

  MyAudioHandler() {
    _loadEmptyPlaylist();

    _notifyAudioHandlerAboutPlaybackEvents();

    _listenForDurationChanges();

    _listenForCurrentSongIndexChanges();

    _listenForProcessingState();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.open(const Playlist([]), play: false);
    } catch (e) {
      print("Error: $e");
    }
  }

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
            "index": mediaItem.extras?.containsKey("index") == true
                ? mediaItem.extras!["index"]
                : generateUniqueID(),
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
                  "index": mediaItem.extras?.containsKey("index") == true
                      ? mediaItem.extras!["index"]
                      : generateUniqueID(),
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
            "index": mediaItem.extras?.containsKey("index") == true
                ? mediaItem.extras!["index"]
                : generateUniqueID(),
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
                "index": mediaItem.extras?.containsKey("index") == true
                    ? mediaItem.extras!["index"]
                    : generateUniqueID(),
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
    final currentIndex = _player.state.playlist.index;

    if (currentIndex >= _player.state.playlist.medias.length) {
      return null;
    }

    final mediaItem = _player.state.playlist.medias[currentIndex];

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

  final m = Mutex();

  Future<List<Media>> preloadPlaylistToIndex(int trackIndex) async {
    await m.acquire();
    realCurrentTrackIndex = trackIndex;

    final List<Media> medias = [];

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

    if (!_player.state.playing) {
      await _player.open(Playlist(medias), play: false);
    } else {
      final l = ListTransformer(_player);
      await l.transform(medias);
    }

    m.release();

    return medias;
  }

  Media _createAudioSource(MediaItem mediaItem) {
    return Media(
      "${mediaItem.extras!['url'] as String}?rn=${mediaItem.extras?["index"]}",
      extras: mediaItem.extras,
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
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await _player.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.previous();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) {
      return;
    }

    try {
      await _listenForCurrentSongIndexChangesStream?.cancel();

      await _player.open(const Playlist([]), play: false);

      final medias = await preloadPlaylistToIndex(index);

      for (int i = 0; i < medias.length; i++) {
        final mediaItem = medias[i];

        if (mediaItem.extras?["index"] == queue.value[index].extras?["index"]) {
          await _player.jump(i);
        }
      }
      _refreshPlaybackState();
    } finally {
      await Future(() {});
      await _listenForCurrentSongIndexChanges();
    }
  }

  StreamSubscription? _listenForCurrentSongIndexChangesStream;

  int? _lastTrackIndexFromPlayer;

  Future<void> _listenForCurrentSongIndexChanges() async {
    _listenForCurrentSongIndexChangesStream =
        _player.stream.position.listen((advertisedIndex) async {
      final trackIndexFromPlayer = getTrackIndexFromPlayer();

      if (trackIndexFromPlayer != null &&
          _lastTrackIndexFromPlayer != trackIndexFromPlayer) {
        await preloadPlaylistToIndex(trackIndexFromPlayer);
      }

      _lastTrackIndexFromPlayer = trackIndexFromPlayer;
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.stream.position.listen((_) => _refreshPlaybackState());
    _player.stream.buffer.listen((_) => _refreshPlaybackState());
    _player.stream.playing.listen((_) => _refreshPlaybackState());
  }

  void _refreshPlaybackState() {
    final playing = _player.state.playing;
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
      playing: playing,
      updatePosition: _player.state.position,
      bufferedPosition: _player.state.buffer,
      speed: _player.state.rate,
      queueIndex: realCurrentTrackIndex,
    ));
  }

  void _listenForDurationChanges() {
    _player.stream.duration.listen((duration) {
      final index = realCurrentTrackIndex;
      final newQueue = queue.value;
      if (newQueue.isEmpty) return;
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForProcessingState() {
    _player.stream.duration.listen((_) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
      ));
    });

    _player.stream.buffering.listen((isBuffering) {
      playbackState.add(playbackState.value.copyWith(
        processingState: isBuffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
      ));
    });

    _player.stream.playing.listen((_) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.ready,
      ));
    });

    _player.stream.completed.listen((completed) {
      playbackState.add(playbackState.value.copyWith(
        processingState: completed
            ? AudioProcessingState.completed
            : AudioProcessingState.ready,
      ));
    });

    _player.stream.error.listen((_) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
      ));
    });
  }
}

class ListTransformer {
  Player player;

  ListTransformer(this.player);

  bool isSameItem(Media a, Media b) {
    return a.extras?["index"] == b.extras?["index"];
  }

  Future<void> transform(List<Media> target) async {
    final List<Media> current = List.from(player.state.playlist.medias);

    outerloop:
    for (int i = current.length - 1; i >= 0; i--) {
      for (final targetTrack in target) {
        if (isSameItem(current[i], targetTrack)) {
          continue outerloop;
        }
      }
      await player.remove(i);
      current.removeAt(i);
    }

    outerloop:
    for (int i = 0; i < target.length; i++) {
      for (final track in current) {
        if (isSameItem(target[i], track)) {
          continue outerloop;
        }
      }
      await player.add(target[i]);
      current.add(target[i]);
    }

    for (int j = 0; j < target.length; j++) {
      for (int i = 0; i < current.length; i++) {
        if (isSameItem(current[i], target[j])) {
          await player.move(i, j);
          int k = j;
          if (i < j) {
            k--;
          }
          current.insert(k, current.removeAt(i));
          break;
        }
      }
    }
  }
}
