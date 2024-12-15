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

  void createPlaylist(Playlist playlist) async {
    final newPlaylist = await _playlistRepository.createPlaylist(playlist);

    if (!_controller.isClosed) {
      _controller.add(newPlaylist);
    }
  }
}
