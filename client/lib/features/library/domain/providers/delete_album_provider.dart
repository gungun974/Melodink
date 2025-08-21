import 'dart:async';

import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_album_provider.g.dart';

@riverpod
class DeleteAlbumStream extends _$DeleteAlbumStream {
  late AlbumRepository _albumRepository;
  late StreamController<Album> _controller;

  @override
  Stream<Album> build() {
    _albumRepository = ref.watch(albumRepositoryProvider);
    _controller = StreamController<Album>.broadcast();

    ref.onDispose(() {
      _controller.close();
    });

    return _controller.stream;
  }

  deleteAlbum(int albumId) async {
    final deletedAlbum = await _albumRepository.deleteAlbumById(albumId);

    if (!_controller.isClosed) {
      _controller.add(deletedAlbum);
    }
  }
}
