import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/data/datasource/playlist_local_data_source.dart';
import 'package:melodink_client/features/library/data/datasource/playlist_remote_data_source.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';

class PlaylistNotFoundException implements Exception {}

class PlaylistRepository {
  final PlaylistRemoteDataSource playlistRemoteDataSource;
  final PlaylistLocalDataSource playlistLocalDataSource;

  final PlayedTrackRepository playedTrackRepository;

  final NetworkInfo networkInfo;

  PlaylistRepository({
    required this.playlistRemoteDataSource,
    required this.playlistLocalDataSource,
    required this.playedTrackRepository,
    required this.networkInfo,
  });

  Future<List<Playlist>> getAllPlaylists() async {
    final localPlaylists = await playlistLocalDataSource.getAllPlaylists();

    if (networkInfo.isServerRecheable()) {
      try {
        final remotePlaylists =
            await playlistRemoteDataSource.getAllPlaylists();

        for (var i = 0; i < remotePlaylists.length; i++) {
          if (localPlaylists
              .any((playlist) => playlist.id == remotePlaylists[i].id)) {
            remotePlaylists[i] =
                remotePlaylists[i].copyWith(isDownloaded: true);
          }
        }

        return remotePlaylists;
      } catch (_) {
        return localPlaylists;
      }
    }

    return await playlistLocalDataSource.getAllPlaylists();
  }

  Future<Playlist> getPlaylistById(int id) async {
    Playlist? playlist = await playlistLocalDataSource.getPlaylistById(id);

    playlist ??= await playlistRemoteDataSource.getPlaylistById(id);

    await playedTrackRepository.loadTrackHistoryIntoMinimalTracks(
      playlist.tracks,
    );

    return playlist;
  }

  Future<void> addPlaylistTracks(
    int playlistId,
    List<MinimalTrack> tracks,
  ) async {
    final playlist = await playlistRemoteDataSource.getPlaylistById(playlistId);

    await playlistRemoteDataSource.setPlaylistTracks(
      playlist.id,
      [...playlist.tracks, ...tracks],
    );

    if (await playlistLocalDataSource.getPlaylistById(playlist.id) != null) {
      await updateAndStorePlaylist(playlist.id);
    }
  }

  Future<void> removePlaylistTracks(
    int playlistId,
    int fromIndex,
    int toIndex,
  ) async {
    final playlist = await playlistRemoteDataSource.getPlaylistById(playlistId);

    await playlistRemoteDataSource.setPlaylistTracks(
      playlist.id,
      [
        ...playlist.tracks.sublist(0, fromIndex),
        ...playlist.tracks.sublist(toIndex + 1),
      ],
    );

    if (await playlistLocalDataSource.getPlaylistById(playlist.id) != null) {
      await updateAndStorePlaylist(playlist.id);
    }
  }

  Future<Playlist> updateAndStorePlaylist(int id) async {
    final playlist = await playlistRemoteDataSource.getPlaylistById(id);
    await playlistLocalDataSource.storePlaylist(playlist);

    await playedTrackRepository.loadTrackHistoryIntoMinimalTracks(
      playlist.tracks,
    );

    return playlist;
  }

  Future<void> deleteStoredPlaylist(int id) async {
    await playlistLocalDataSource.deleteStoredPlaylist(id);
  }

  Future<bool> isPlaylistDownloaded(int id) async {
    final playlist = await playlistLocalDataSource.getPlaylistById(id);

    return playlist != null;
  }
}

final playlistRepositoryProvider = Provider(
  (ref) => PlaylistRepository(
    playlistRemoteDataSource: ref.watch(
      playlistRemoteDataSourceProvider,
    ),
    playlistLocalDataSource: ref.watch(
      playlistLocalDataSourceProvider,
    ),
    playedTrackRepository: ref.watch(
      playedTrackRepositoryProvider,
    ),
    networkInfo: ref.watch(
      networkInfoProvider,
    ),
  ),
);
