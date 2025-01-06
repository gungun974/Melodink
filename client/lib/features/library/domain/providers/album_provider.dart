import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/domain/providers/edit_album_provider.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/providers/delete_track_provider.dart';
import 'package:melodink_client/features/track/domain/providers/download_manager_provider.dart';
import 'package:melodink_client/features/track/domain/providers/edit_track_provider.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_provider.g.dart';

//! Albums

@riverpod
Future<List<Album>> allAlbums(Ref ref) async {
  final albumRepository = ref.read(albumRepositoryProvider);

  ref.listen(editAlbumStreamProvider, (_, rawNewAlbum) async {
    final newAlbum = rawNewAlbum.valueOrNull;

    if (newAlbum == null) {
      return;
    }

    ref.invalidateSelf();
  });

  return await albumRepository.getAllAlbums();
}

final allAlbumsSortedModeProvider =
    StateProvider.autoDispose<String>((ref) => 'newest');

final allAlbumsSearchInputProvider =
    StateProvider.autoDispose<String>((ref) => '');

int compareArtists(List<MinimalArtist> a, List<MinimalArtist> b) {
  int minLength = a.length < b.length ? a.length : b.length;

  for (int i = 0; i < minLength; i++) {
    if (a[i].name.isEmpty && b[i].name.isNotEmpty) {
      return 1;
    }

    if (b[i].name.isEmpty && a[i].name.isNotEmpty) {
      return -1;
    }

    int comparison = a[i].name.toLowerCase().compareTo(b[i].name.toLowerCase());
    if (comparison != 0) {
      return comparison;
    }
  }

  return a.length.compareTo(b.length);
}

@riverpod
Future<List<Album>> allAlbumsSorted(Ref ref) async {
  final allAlbums = await ref.watch(allAlbumsProvider.future);

  final sortedMode = ref.watch(allAlbumsSortedModeProvider);

  return allAlbums.toList(growable: false)
    ..sort(
      (a, b) {
        return switch (sortedMode) {
          // Artist Z-A
          "artist-za" => compareArtists(b.albumArtists, a.albumArtists),
          // Artist A-Z
          "artist-az" => compareArtists(a.albumArtists, b.albumArtists),
          // Name Z-A
          "name-za" => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          // Name A-Z
          "name-az" => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          // Oldest
          "oldest" => a.lastTrackDateAdded.compareTo(b.lastTrackDateAdded),
          // Newest
          _ => b.lastTrackDateAdded.compareTo(a.lastTrackDateAdded),
        };
      },
    );
}

@riverpod
Future<List<Album>> allSearchAlbums(Ref ref) async {
  final allAlbums = await ref.watch(allAlbumsSortedProvider.future);

  final keepAlphanumeric = RegExp(r'[^a-zA-Z0-9]');

  final allAlbumsSearchInput = ref
      .watch(allAlbumsSearchInputProvider)
      .toLowerCase()
      .trim()
      .replaceAll(keepAlphanumeric, "");

  if (allAlbumsSearchInput.isEmpty) {
    return allAlbums;
  }

  return allAlbums.where((album) {
    if (album.name
        .toLowerCase()
        .replaceAll(keepAlphanumeric, "")
        .contains(allAlbumsSearchInput)) {
      return true;
    }

    for (final artist in album.albumArtists) {
      if (artist.name
          .toLowerCase()
          .replaceAll(keepAlphanumeric, "")
          .contains(allAlbumsSearchInput)) {
        return true;
      }
    }

    return false;
  }).toList();
}

//! Album Page

@riverpod
class AlbumById extends _$AlbumById {
  late PlayedTrackRepository _playedTrackRepository;

  @override
  Future<Album> build(String id) async {
    final albumRepository = ref.watch(albumRepositoryProvider);
    _playedTrackRepository = ref.watch(playedTrackRepositoryProvider);

    final manager = ref.watch(playerTrackerManagerProvider);

    final subscription = manager.newPlayedTrack.listen((playedTrack) {
      reloadTrackHistoryInfo(playedTrack.trackId);
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    ref.listen(editAlbumStreamProvider, (_, rawNewAlbum) async {
      final newAlbum = rawNewAlbum.valueOrNull;

      if (newAlbum == null) {
        return;
      }

      if (newAlbum.id != id) {
        return;
      }

      ref.invalidateSelf();

      ref
          .read(albumDownloadNotifierProvider(id).notifier)
          .refresh(shouldCheckDownload: true);
    });

    ref.listen(trackEditStreamProvider, (_, rawNewTrack) async {
      final newTrackInfo = rawNewTrack.valueOrNull;

      if (newTrackInfo == null) {
        return;
      }

      final newTrack = newTrackInfo.track;

      final info =
          await _playedTrackRepository.getTrackHistoryInfo(newTrack.id);

      final album = await future;

      final updatedTracks = album.tracks.map((track) {
        return track.id == newTrack.id
            ? newTrack.toMinimalTrack().copyWith(historyInfo: () => info)
            : track;
      }).toList();

      state = AsyncData(album.copyWith(tracks: updatedTracks));

      ref.read(albumDownloadNotifierProvider(id).notifier).refresh(
            shouldCheckDownload: newTrackInfo.shouldCheckDownload,
          );
    });

    ref.listen(trackDeleteStreamProvider, (_, rawDeletedTrack) async {
      final deletedTrack = rawDeletedTrack.valueOrNull;

      if (deletedTrack == null) {
        return;
      }

      final album = await future;

      final updatedTracks = album.tracks
          .where(
            (track) => track.id != deletedTrack.id,
          )
          .toList();

      state = AsyncData(album.copyWith(tracks: updatedTracks));

      ref
          .read(albumDownloadNotifierProvider(id).notifier)
          .refresh(shouldCheckDownload: false);
    });

    final album = await albumRepository.getAlbumById(id);

    return album;
  }

  reloadTrackHistoryInfo(int trackId) async {
    final info = await _playedTrackRepository.getTrackHistoryInfo(trackId);

    final album = await future;

    final updatedTracks = album.tracks.map((track) {
      return track.id == trackId
          ? track.copyWith(historyInfo: () => info)
          : track;
    }).toList();

    state = AsyncData(album.copyWith(tracks: updatedTracks));
  }
}

//! Album Download

class AlbumDownloadState extends Equatable {
  final bool downloaded;

  final bool isLoading;

  final AlbumDownloadError? error;

  const AlbumDownloadState({
    required this.downloaded,
    required this.isLoading,
    required this.error,
  });

  AlbumDownloadState copyWith({
    bool? downloaded,
    bool? isLoading,
  }) {
    return AlbumDownloadState(
      downloaded: downloaded ?? this.downloaded,
      isLoading: isLoading ?? this.isLoading,
      error: null,
    );
  }

  AlbumDownloadState copyWithError({
    bool? downloaded,
    bool? isLoading,
    required AlbumDownloadError error,
  }) {
    return AlbumDownloadState(
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

class AlbumDownloadError extends Equatable {
  final String? title;
  final String message;

  const AlbumDownloadError({
    this.title,
    required this.message,
  });

  @override
  List<Object?> get props => [title, message];
}

@riverpod
class AlbumDownloadNotifier extends _$AlbumDownloadNotifier {
  @override
  AlbumDownloadState build(String albumId) {
    refresh(shouldCheckDownload: true);

    return const AlbumDownloadState(
      downloaded: false,
      isLoading: false,
      error: null,
    );
  }

  refresh({
    required bool shouldCheckDownload,
  }) {
    ref
        .read(albumRepositoryProvider)
        .isAlbumDownloaded(albumId)
        .then((downloaded) {
      state = state.copyWith(downloaded: downloaded);

      print(downloaded);
      if (downloaded) {
        download(shouldCheckDownload: shouldCheckDownload);
      }
    });
  }

  download({
    required bool shouldCheckDownload,
  }) async {
    if (state.isLoading) {
      return;
    }

    final albumRepository = ref.read(albumRepositoryProvider);

    state = state.copyWith(isLoading: true);
    try {
      final newAlbum = await albumRepository.updateAndStoreAlbum(albumId, true);

      state = state.copyWith(
        isLoading: false,
        downloaded: true,
      );

      if (shouldCheckDownload) {
        final downloadManagerNotifier =
            ref.read(downloadManagerNotifierProvider.notifier);

        downloadManagerNotifier.addTracksToDownloadTodo(
          newAlbum.tracks,
        );
      }

      ref.invalidate(allAlbumsProvider);
      ref.invalidate(albumByIdProvider(albumId));
    } catch (e) {
      state = state.copyWithError(
        isLoading: false,
        error: const AlbumDownloadError(message: "An error was not expected"),
      );
    }
  }

  deleteDownloaded() async {
    if (state.isLoading) {
      return;
    }

    final albumRepository = ref.read(albumRepositoryProvider);

    state = state.copyWith(isLoading: true);
    try {
      await albumRepository.deleteStoredAlbum(albumId);

      final downloadManagerNotifier =
          ref.read(downloadManagerNotifierProvider.notifier);

      await downloadManagerNotifier.deleteOrphanTracks();

      state = state.copyWith(
        isLoading: false,
        downloaded: false,
      );

      ref.invalidate(allAlbumsProvider);
    } catch (e) {
      state = state.copyWithError(
        isLoading: false,
        error: const AlbumDownloadError(message: "An error was not expected"),
      );
    }
  }
}

@riverpod
Future<List<MinimalTrack>> albumSortedTracks(Ref ref, String albumId) async {
  final album = await ref.watch(albumByIdProvider(albumId).future);

  final tracks = [...album.tracks];

  tracks.sort((a, b) {
    int discCompare = a.discNumber.compareTo(b.discNumber);
    if (discCompare != 0) {
      return discCompare;
    }

    int trackCompare = a.trackNumber.compareTo(b.trackNumber);
    if (trackCompare != 0) {
      return trackCompare;
    }

    return a.title.compareTo(b.title);
  });

  return tracks;
}
