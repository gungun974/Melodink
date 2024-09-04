import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
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

  final _executor = AsyncExecutor();

  final _mutex = Mutex();

  @override
  DownloadState build() {
    _downloadTrackRepository = ref.read(downloadTrackRepositoryProvider);

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
    final currentTrack = ref.read(audioControllerProvider);

    final orphans = await _downloadTrackRepository.getOrphanTracks();

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
      currentTrack.currentTrack.value?.id,
    );
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
