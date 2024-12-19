import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/library/data/datasource/album_local_data_source.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:mutex/mutex.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_manager_provider.g.dart';

class DownloadTask extends Equatable {
  final MinimalTrack track;
  final Stream<double> progress;
  final StreamController<double> progressController;

  const DownloadTask({
    required this.track,
    required this.progress,
    required this.progressController,
  });

  DownloadTask copyWith({
    MinimalTrack? track,
  }) {
    return DownloadTask(
      track: track ?? this.track,
      progress: progress,
      progressController: progressController,
    );
  }

  @override
  List<Object> get props => [
        track,
        progress,
        progressController,
      ];
}

class DownloadState extends Equatable {
  final List<DownloadTask> queueTasks;

  final bool isDownloading;

  DownloadTask? get currentTask => queueTasks.firstOrNull;

  const DownloadState({
    required this.queueTasks,
    required this.isDownloading,
  });

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
  List<Object?> get props => [
        queueTasks,
      ];
}

@Riverpod(keepAlive: true)
class DownloadManagerNotifier extends _$DownloadManagerNotifier {
  late DownloadTrackRepository _downloadTrackRepository;
  late AudioController _audioController;

  final _executor = AsyncExecutor();

  final _mutex = Mutex();

  int? _lastCurrentTrackId;

  @override
  DownloadState build() {
    _downloadTrackRepository = ref.read(downloadTrackRepositoryProvider);
    _audioController = ref.read(audioControllerProvider);

    _audioController.currentTrack.stream.listen((track) async {
      await Future.delayed(
        const Duration(milliseconds: 10),
      );

      if (track != null && _lastCurrentTrackId != track.id) {
        _lastCurrentTrackId = track.id;
        deleteOrphanTracks();
      }
    });

    return const DownloadState(
      queueTasks: [],
      isDownloading: false,
    );
  }

  addTracksToDownloadTodo(List<MinimalTrack> tracks) {
    state = state.copyWith(queueTasks: [
      ...state.queueTasks,
      ...tracks.map((track) {
        final streamController = StreamController<double>();

        return DownloadTask(
          track: track,
          progress: streamController.stream.asBroadcastStream(),
          progressController: streamController,
        );
      }),
    ]);

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

        final result =
            await _downloadTrackRepository.shouldDownloadOrUpdateTrack(
          currentTask.track.id,
        );

        if (result.shouldDownload) {
          if (!state.isDownloading) {
            state = state.copyWith(
              isDownloading: true,
            );
          }

          currentTask.progressController.add(0);

          await _downloadTrackRepository.downloadOrUpdateTrack(
            currentTask.track.id,
            result.signature,
            result.coverSignature,
            currentTask.progressController,
          );
        }

        currentTask.progressController.close();

        state = state.copyWith(
          queueTasks: state.queueTasks.skip(1).toList(),
        );

        _mutex.release();

        await _audioController.reloadPlayerTracks();

        final _ = ref.refresh(isTrackDownloadedProvider(currentTask.track.id));

        if (state.isDownloading && state.queueTasks.isEmpty) {
          state = state.copyWith(
            isDownloading: false,
          );
        }
      } catch (e) {
        state = state.copyWith(
          queueTasks: [
            ...state.queueTasks.skip(1),
            state.queueTasks.first,
          ],
        );

        _mutex.release();

        if (state.isDownloading && state.queueTasks.isEmpty) {
          state = state.copyWith(
            isDownloading: false,
          );
        }

        await Future.delayed(
          const Duration(seconds: 1),
        );
      }
    }
  }

  deleteOrphanTracks() async {
    final orphans = await _downloadTrackRepository.getOrphanTracks();

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
    _mutex.release();

    await _downloadTrackRepository.deleteOrphanTracks(
      _audioController.currentTrack.value?.id,
    );

    await _audioController.reloadPlayerTracks();

    for (final orphan in orphans) {
      final _ = ref.refresh(isTrackDownloadedProvider(orphan.trackId));
    }
  }

  Future<void> downloadAllAlbums() async {
    final albumRepository = ref.read(albumRepositoryProvider);

    final albums = await albumRepository.updateAndStoreAllAlbums(true);

    final Set<int> trackIds = {};
    final List<MinimalTrack> tracks = [];

    for (final album in albums) {
      for (final track in album.tracks) {
        if (trackIds.add(track.id)) {
          tracks.add(track);
        }
      }
    }

    state = state.copyWith(queueTasks: [
      ...state.queueTasks,
      ...tracks.map((track) {
        final streamController = StreamController<double>();

        return DownloadTask(
          track: track,
          progress: streamController.stream.asBroadcastStream(),
          progressController: streamController,
        );
      }),
    ]);

    _executor.execute(_manageDownload);
  }

  Future<void> removeAllDownloads() async {
    final playlistRepository = ref.read(playlistRepositoryProvider);

    final playlists = await playlistRepository.getAllPlaylists();

    for (final playlist in playlists) {
      try {
        await playlistRepository.deleteStoredPlaylist(playlist.id);
      } on PlaylistNotFoundException {
        //
      }
    }

    final albumRepository = ref.read(albumRepositoryProvider);

    final albums = await albumRepository.getAllAlbums();

    for (final album in albums) {
      try {
        await albumRepository.deleteStoredAlbum(album.id);
      } on AlbumNotFoundException {
        //
      }
    }

    await albumRepository.deleteOrphanAlbums();
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

@riverpod
bool isDownloadManagerRunning(
  IsDownloadManagerRunningRef ref,
) {
  final downloadManager = ref.watch(downloadManagerNotifierProvider);

  return downloadManager.isDownloading;
}

@riverpod
DownloadTask? currentDownloadManagerTask(
  CurrentDownloadManagerTaskRef ref,
) {
  final downloadManager = ref.watch(downloadManagerNotifierProvider);

  return downloadManager.currentTask;
}
