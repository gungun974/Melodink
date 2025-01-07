import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/data/datasource/album_local_data_source.dart';
import 'package:melodink_client/features/library/data/datasource/playlist_local_data_source.dart';
import 'package:melodink_client/features/library/data/datasource/playlist_remote_data_source.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';

class PlaylistNotFoundException implements Exception {}

class PlaylistRepository {
  final PlaylistRemoteDataSource playlistRemoteDataSource;
  final PlaylistLocalDataSource playlistLocalDataSource;

  final AlbumLocalDataSource albumLocalDataSource;

  final PlayedTrackRepository playedTrackRepository;

  final NetworkInfo networkInfo;

  PlaylistRepository({
    required this.playlistRemoteDataSource,
    required this.playlistLocalDataSource,
    required this.albumLocalDataSource,
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

        final remoteIds =
            remotePlaylists.map((playlist) => playlist.id).toSet();

        final extraLocalPlaylists = localPlaylists
            .where((playlist) => !remoteIds.contains(playlist.id))
            .toList();

        for (final playlist in extraLocalPlaylists) {
          await playlistLocalDataSource.deleteStoredPlaylist(playlist.id);
        }

        await albumLocalDataSource.deleteOrphanAlbums();

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

  Future<Playlist> setPlaylistTracks(
    int playlistId,
    List<MinimalTrack> tracks,
  ) async {
    final playlist = await playlistRemoteDataSource.getPlaylistById(playlistId);

    final newPlaylist = await playlistRemoteDataSource.setPlaylistTracks(
      playlist.id,
      tracks,
    );

    if (await playlistLocalDataSource.getPlaylistById(playlist.id) != null) {
      await updateAndStorePlaylist(playlist.id);
    }

    return newPlaylist;
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

  Future<Playlist> createPlaylist(Playlist playlist) async {
    return playlistRemoteDataSource.createPlaylist(playlist);
  }

  Future<Playlist> duplicatePlaylist(int playlistId) {
    return playlistRemoteDataSource.duplicatePlaylist(playlistId);
  }

  Future<Playlist> savePlaylist(Playlist playlist) async {
    return playlistRemoteDataSource.savePlaylist(playlist);
  }

  Future<bool> isPlaylistDownloaded(int id) async {
    final playlist = await playlistLocalDataSource.getPlaylistById(id);

    return playlist != null;
  }

  Future<Playlist> changePlaylistCover(int id, File file) async {
    return await playlistRemoteDataSource.changePlaylistCover(id, file);
  }

  Future<Playlist> removePlaylistCover(int id) async {
    return await playlistRemoteDataSource.removePlaylistCover(id);
  }

  Future<Playlist> deletePlaylistById(int playlistId) async {
    final playlist =
        await playlistRemoteDataSource.deletePlaylistById(playlistId);

    final savedPlaylist =
        await playlistLocalDataSource.getPlaylistById(playlist.id);

    if (savedPlaylist != null) {
      await playlistLocalDataSource.deleteStoredPlaylist(playlist.id);
    }

    return playlist;
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
    albumLocalDataSource: ref.watch(
      albumLocalDataSourceProvider,
    ),
    playedTrackRepository: ref.watch(
      playedTrackRepositoryProvider,
    ),
    networkInfo: ref.watch(
      networkInfoProvider,
    ),
  ),
);
