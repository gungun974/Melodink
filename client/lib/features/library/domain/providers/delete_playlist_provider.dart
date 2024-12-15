import 'dart:async';

import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/domain/providers/download_manager_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_playlist_provider.g.dart';

@riverpod
class DeletePlaylistStream extends _$DeletePlaylistStream {
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

  deletePlaylist(int playlistId) async {
    final deletedPlaylist =
        await _playlistRepository.deletePlaylistById(playlistId);

    await ref
        .read(downloadManagerNotifierProvider.notifier)
        .deleteOrphanTracks();

    if (!_controller.isClosed) {
      _controller.add(deletedPlaylist);
    }
  }
}
