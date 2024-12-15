import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/providers/create_playlist_provider.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/providers/delete_track_provider.dart';
import 'package:melodink_client/features/track/domain/providers/download_manager_provider.dart';
import 'package:melodink_client/features/track/domain/providers/edit_track_provider.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'playlist_provider.g.dart';

@riverpod
Future<List<Playlist>> allPlaylists(AllPlaylistsRef ref) async {
  final playlistRepository = ref.read(playlistRepositoryProvider);

  ref.listen(createPlaylistStreamProvider, (_, rawNewPlaylist) async {
    final newPlaylist = rawNewPlaylist.valueOrNull;

    if (newPlaylist == null) {
      return;
    }

    ref.invalidateSelf();
  });

  return await playlistRepository.getAllPlaylists();
}

@riverpod
class PlaylistById extends _$PlaylistById {
  late PlayedTrackRepository _playedTrackRepository;

  @override
  Future<Playlist> build(int id) async {
    final playlistRepository = ref.watch(playlistRepositoryProvider);
    _playedTrackRepository = ref.watch(playedTrackRepositoryProvider);

    final manager = ref.watch(playerTrackerManagerProvider);

    final subscription = manager.newPlayedTrack.listen((playedTrack) {
      reloadTrackHistoryInfo(playedTrack.trackId);
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    ref.listen(trackEditStreamProvider, (_, rawNewTrack) async {
      final newTrack = rawNewTrack.valueOrNull;

      if (newTrack == null) {
        return;
      }

      await updateTrack(newTrack);
    });

    ref.listen(trackDeleteStreamProvider, (_, rawDeletedTrack) async {
      final deletedTrack = rawDeletedTrack.valueOrNull;

      if (deletedTrack == null) {
        return;
      }

      final playlist = await future;

      final updatedTracks = playlist.tracks
          .where(
            (track) => track.id != deletedTrack.id,
          )
          .toList();

      state = AsyncData(playlist.copyWith(tracks: updatedTracks));

      ref.invalidate(playlistDownloadNotifierProvider(id));
    });

    final result = await playlistRepository.getPlaylistById(id);

    return result;
  }

  reloadTrackHistoryInfo(int trackId) async {
    final info = await _playedTrackRepository.getTrackHistoryInfo(trackId);

    final playlist = await future;

    final updatedTracks = playlist.tracks.map((track) {
      return track.id == trackId
          ? track.copyWith(historyInfo: () => info)
          : track;
    }).toList();

    state = AsyncData(playlist.copyWith(tracks: updatedTracks));
  }

  updateTrack(Track newTrack) async {
    final info = await _playedTrackRepository.getTrackHistoryInfo(newTrack.id);

    final playlist = await future;

    final updatedTracks = playlist.tracks.map((track) {
      return track.id == newTrack.id
          ? newTrack.toMinimalTrack().copyWith(historyInfo: () => info)
          : track;
    }).toList();

    state = AsyncData(playlist.copyWith(tracks: updatedTracks));

    ref.invalidate(playlistDownloadNotifierProvider(id));
  }
}

class PlaylistDownloadState extends Equatable {
  final bool downloaded;

  final bool isLoading;

  final PlaylistDownloadError? error;

  const PlaylistDownloadState({
    required this.downloaded,
    required this.isLoading,
    required this.error,
  });

  PlaylistDownloadState copyWith({
    bool? downloaded,
    bool? isLoading,
  }) {
    return PlaylistDownloadState(
      downloaded: downloaded ?? this.downloaded,
      isLoading: isLoading ?? this.isLoading,
      error: null,
    );
  }

  PlaylistDownloadState copyWithError({
    bool? downloaded,
    bool? isLoading,
    required PlaylistDownloadError error,
  }) {
    return PlaylistDownloadState(
      downloaded: downloaded ?? this.downloaded,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        downloaded,
        isLoading,
        error,
      ];
}

class PlaylistDownloadError extends Equatable {
  final String? title;
  final String message;

  const PlaylistDownloadError({
    this.title,
    required this.message,
  });

  @override
  List<Object?> get props => [title, message];
}

@riverpod
class PlaylistDownloadNotifier extends _$PlaylistDownloadNotifier {
  @override
  PlaylistDownloadState build(int playlistId) {
    ref
        .watch(playlistRepositoryProvider)
        .isPlaylistDownloaded(playlistId)
        .then((downloaded) {
      state = state.copyWith(downloaded: downloaded);

      if (downloaded) {
        download();
      }
    });

    return const PlaylistDownloadState(
      downloaded: false,
      isLoading: false,
      error: null,
    );
  }

  download() async {
    if (state.isLoading) {
      return;
    }

    final playlistRepository = ref.read(playlistRepositoryProvider);

    state = state.copyWith(isLoading: true);
    try {
      final newPlaylist =
          await playlistRepository.updateAndStorePlaylist(playlistId);

      state = state.copyWith(
        isLoading: false,
        downloaded: true,
      );

      final downloadManagerNotifier =
          ref.read(downloadManagerNotifierProvider.notifier);

      downloadManagerNotifier.addTracksToDownloadTodo(
        newPlaylist.tracks,
      );

      ref.invalidate(allPlaylistsProvider);
      ref.invalidate(playlistByIdProvider(playlistId));
    } catch (e) {
      state = state.copyWithError(
        isLoading: false,
        error:
            const PlaylistDownloadError(message: "An error was not expected"),
      );
    }
  }

  deleteDownloaded() async {
    if (state.isLoading) {
      return;
    }

    final playlistRepository = ref.read(playlistRepositoryProvider);

    state = state.copyWith(isLoading: true);
    try {
      await playlistRepository.deleteStoredPlaylist(playlistId);

      final downloadManagerNotifier =
          ref.read(downloadManagerNotifierProvider.notifier);

      await downloadManagerNotifier.deleteOrphanTracks();

      state = state.copyWith(
        isLoading: false,
        downloaded: false,
      );

      ref.invalidate(allPlaylistsProvider);
    } catch (e) {
      state = state.copyWithError(
        isLoading: false,
        error:
            const PlaylistDownloadError(message: "An error was not expected"),
      );
    }
  }
}

@riverpod
List<MinimalTrack> playlistSortedTracks(
    PlaylistSortedTracksRef ref, int playlistId) {
  final asyncPlaylist = ref.watch(playlistByIdProvider(playlistId));

  final playlist = asyncPlaylist.valueOrNull;

  if (playlist == null) {
    return [];
  }

  final tracks = [...playlist.tracks];

  return tracks;
}
