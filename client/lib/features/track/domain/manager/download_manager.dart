import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/data/repository/download_album_repository.dart';
import 'package:melodink_client/features/library/data/repository/download_playlist_repository.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/events/download_events.dart';
import 'package:mutex/mutex.dart';

class DownloadTask extends Equatable {
  final Track track;
  final Stream<double> progress;
  final StreamController<double> progressController;

  const DownloadTask({
    required this.track,
    required this.progress,
    required this.progressController,
  });

  DownloadTask copyWith({Track? track}) {
    return DownloadTask(
      track: track ?? this.track,
      progress: progress,
      progressController: progressController,
    );
  }

  @override
  List<Object> get props => [track, progress, progressController];
}

class DownloadState extends Equatable {
  final List<DownloadTask> queueTasks;

  final bool isDownloading;

  DownloadTask? get currentTask => queueTasks.firstOrNull;

  const DownloadState({required this.queueTasks, required this.isDownloading});

  DownloadState copyWith({
    List<DownloadTask>? queueTasks,
    bool? isDownloading,
  }) {
    return DownloadState(
      queueTasks: queueTasks ?? this.queueTasks,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }

  @override
  List<Object?> get props => [queueTasks];
}

class DownloadManager extends ChangeNotifier {
  final EventBus eventBus;
  final AudioController audioController;
  final AlbumRepository albumRepository;
  final DownloadTrackRepository downloadTrackRepository;
  final DownloadAlbumRepository downloadAlbumRepository;
  final DownloadPlaylistRepository downloadPlaylistRepository;

  DownloadManager({
    required this.eventBus,
    required this.audioController,
    required this.albumRepository,
    required this.downloadTrackRepository,
    required this.downloadPlaylistRepository,
    required this.downloadAlbumRepository,
  }) {
    audioController.currentTrack.stream.listen((track) async {
      await Future.delayed(const Duration(milliseconds: 10));

      if (track != null && _lastCurrentTrackId != track.id) {
        _lastCurrentTrackId = track.id;
        deleteOrphanTracks();
      }
    });
  }

  final _executor = AsyncExecutor();

  final _mutex = Mutex();

  int? _lastCurrentTrackId;

  DownloadState state = const DownloadState(
    queueTasks: [],
    isDownloading: false,
  );

  void addTracksToDownloadTodo(List<Track> tracks) {
    state = state.copyWith(
      queueTasks: [
        ...state.queueTasks,
        ...tracks.map((track) {
          final streamController = StreamController<double>();

          return DownloadTask(
            track: track,
            progress: streamController.stream.asBroadcastStream(),
            progressController: streamController,
          );
        }),
      ],
    );
    notifyListeners();

    _executor.execute(_manageDownload);
  }

  Future<void> _manageDownload() async {
    while (state.queueTasks.isNotEmpty) {
      await _mutex.acquire();
      try {
        final currentTask = state.currentTask;

        if (currentTask == null) {
          _mutex.release();

          continue;
        }

        if (!NetworkInfo().isServerRecheable()) {
          currentTask.progressController.close();

          state = state.copyWith(queueTasks: state.queueTasks.skip(1).toList());
          notifyListeners();

          _mutex.release();

          continue;
        }

        final result = await downloadTrackRepository
            .shouldDownloadOrUpdateTrack(currentTask.track);

        if (result.shouldDownload) {
          if (!state.isDownloading) {
            state = state.copyWith(isDownloading: true);
            notifyListeners();
          }

          await downloadTrackRepository.downloadOrUpdateTrack(
            currentTask.track.id,
            result.signature,
            result.coverSignature,
            result.audioQuality,
            currentTask.progressController,
          );
        }

        currentTask.progressController.close();

        state = state.copyWith(queueTasks: state.queueTasks.skip(1).toList());
        notifyListeners();

        _mutex.release();

        if (result.shouldDownload) {
          await audioController.reloadPlayerTracks();

          eventBus.fire(
            DownloadTrackEvent(trackId: currentTask.track.id, downloaded: true),
          );
        }

        if (state.isDownloading && state.queueTasks.isEmpty) {
          state = state.copyWith(isDownloading: false);
          notifyListeners();
        }
      } catch (e) {
        state = state.copyWith(
          queueTasks: [...state.queueTasks.skip(1), state.queueTasks.first],
        );
        notifyListeners();

        _mutex.release();

        if (state.isDownloading && state.queueTasks.isEmpty) {
          state = state.copyWith(isDownloading: false);
          notifyListeners();
        }

        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> deleteOrphanTracks() async {
    final orphans = await downloadTrackRepository.getOrphanTracks();

    if (orphans.isEmpty) {
      return;
    }

    await _mutex.acquire();
    state = state.copyWith(
      queueTasks: state.queueTasks
          .where(
            (track) =>
                orphans.any((orphan) => orphan.trackId == track.track.id),
          )
          .toList(),
    );
    notifyListeners();
    _mutex.release();

    await downloadTrackRepository.deleteOrphanTracks(
      audioController.currentTrack.value?.id,
    );

    await audioController.reloadPlayerTracks();

    for (final orphan in orphans) {
      eventBus.fire(
        DownloadTrackEvent(trackId: orphan.trackId, downloaded: false),
      );
    }
  }

  Future<void> downloadAllAlbums(
    StreamController<double>? streamController,
  ) async {
    final albums = await albumRepository.getAllAlbums();

    final Set<int> trackIds = {};
    final List<Track> tracks = [];

    for (final indexed in albums.indexed) {
      streamController?.add(indexed.$1 / albums.length);

      final album = await albumRepository.getAlbumById(indexed.$2.id);

      await downloadAlbumRepository.downloadAlbum(album.id);

      for (final track in album.tracks) {
        if (trackIds.add(track.id)) {
          tracks.add(track);
        }
      }
    }

    state = state.copyWith(
      queueTasks: [
        ...state.queueTasks,
        ...tracks.map((track) {
          final streamController = StreamController<double>();

          return DownloadTask(
            track: track,
            progress: streamController.stream.asBroadcastStream(),
            progressController: streamController,
          );
        }),
      ],
    );
    notifyListeners();

    _executor.execute(_manageDownload);
  }

  Future<void> removeAllDownloads() async {
    await downloadPlaylistRepository.freeAllPlaylists();

    await downloadAlbumRepository.freeAllAlbums();

    await deleteOrphanTracks();
  }
}

class AsyncExecutor {
  Future<void>? _currentTask;

  Future execute(Future<void> Function() task) async {
    if (_currentTask != null) {
      return;
    }

    _currentTask = task();

    await _currentTask;

    _currentTask = null;

    return;
  }
}
