import 'dart:async';

import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_playlist_provider.g.dart';

@riverpod
class CreatePlaylistStream extends _$CreatePlaylistStream {
  late PlaylistRepository _playlistRepository;
  late StreamController<Playlist> _controller;

  @override
  Stream<Playlist> build() {
    _playlistRepository = ref.watch(playlistRepositoryProvider);
    _controller = StreamController<Playlist>.broadcast();

    ref.onDispose(() {
      _controller.close();
    });

    return _controller.stream;
  }

  Future<Playlist> createPlaylist(Playlist playlist) async {
    Playlist newPlaylist = await _playlistRepository.createPlaylist(playlist);

    if (playlist.tracks.isNotEmpty) {
      newPlaylist = await _playlistRepository.setPlaylistTracks(
        newPlaylist.id,
        playlist.tracks,
      );
    }

    if (!_controller.isClosed) {
      _controller.add(newPlaylist);
    }

    return newPlaylist;
  }

  Future<Playlist> duplicatePlaylist(int playlistId) async {
    final newPlaylist = await _playlistRepository.duplicatePlaylist(playlistId);

    if (!_controller.isClosed) {
      _controller.add(newPlaylist);
    }

    return newPlaylist;
  }
}
