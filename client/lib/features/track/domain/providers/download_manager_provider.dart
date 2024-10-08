import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:mutex/mutex.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_manager_provider.g.dart';

class DownloadState extends Equatable {
  final List<MinimalTrack> queueTracks;

  MinimalTrack? get currentTrack => queueTracks.firstOrNull;

  const DownloadState({
    required this.queueTracks,
  });

  DownloadState copyWith({
    List<MinimalTrack>? queueTracks,
  }) {
    return DownloadState(
      queueTracks: queueTracks ?? this.queueTracks,
    );
  }

  @override
  List<Object?> get props => [
        queueTracks,
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
      queueTracks: [],
    );
  }

  addTracksToDownloadTodo(List<MinimalTrack> tracks) {
    state = state.copyWith(queueTracks: [
      ...state.queueTracks,
      ...tracks,
    ]);

    _executor.execute(_manageDownload);
  }

  Future<void> _manageDownload() async {
    while (state.queueTracks.isNotEmpty) {
      await _mutex.acquire();
      try {
        final currentTrack = state.currentTrack;

        if (currentTrack == null) {
          _mutex.release();

          continue;
        }

        await _downloadTrackRepository.downloadOrUpdateTrack(
          currentTrack.id,
        );

        state = state.copyWith(
          queueTracks: state.queueTracks.skip(1).toList(),
        );

        _mutex.release();

        await _audioController.reloadPlayerTracks();

        final _ = ref.refresh(isTrackDownloadedProvider(currentTrack.id));
      } catch (e) {
        state = state.copyWith(
          queueTracks: [
            ...state.queueTracks.skip(1),
            state.queueTracks.first,
          ],
        );

        _mutex.release();

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
      queueTracks: state.queueTracks
          .where(
            (track) => orphans.any((orphan) => orphan.trackId == track.id),
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
