import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/providers/download_manager_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_provider.g.dart';

@riverpod
Future<List<Album>> allAlbums(AllAlbumsRef ref) async {
  final albumRepository = ref.read(albumRepositoryProvider);

  return await albumRepository.getAllAlbums();
}

@riverpod
Future<Album> albumById(AlbumByIdRef ref, String id) async {
  final albumRepository = ref.watch(albumRepositoryProvider);

  final album = await albumRepository.getAlbumById(id);

  return album;
}

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
    ref
        .read(albumRepositoryProvider)
        .isAlbumDownloaded(albumId)
        .then((downloaded) {
      state = state.copyWith(downloaded: downloaded);

      if (downloaded) {
        download();
      }
    });

    return const AlbumDownloadState(
      downloaded: false,
      isLoading: false,
      error: null,
    );
  }

  download() async {
    if (state.isLoading) {
      return;
    }

    final albumRepository = ref.read(albumRepositoryProvider);

    state = state.copyWith(isLoading: true);
    try {
      final newAlbum = await albumRepository.updateAndStoreAlbum(albumId);

      state = state.copyWith(
        isLoading: false,
        downloaded: true,
      );

      final downloadManagerNotifier =
          ref.read(downloadManagerNotifierProvider.notifier);

      downloadManagerNotifier.addTracksToDownloadTodo(
        newAlbum.tracks,
      );

      final _ = ref.refresh(allAlbumsProvider);
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

      final _ = ref.refresh(allAlbumsProvider);
    } catch (e) {
      state = state.copyWithError(
        isLoading: false,
        error: const AlbumDownloadError(message: "An error was not expected"),
      );
    }
  }
}

@riverpod
List<MinimalTrack> albumSortedTracks(AlbumSortedTracksRef ref, String albumId) {
  final asyncAlbum = ref.watch(albumByIdProvider(albumId));

  final album = asyncAlbum.valueOrNull;

  if (album == null) {
    return [];
  }

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
