import 'dart:async';

import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_album_provider.g.dart';

@riverpod
class CreateAlbumStream extends _$CreateAlbumStream {
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

  Future<Album> createAlbum(Album album) async {
    final newAlbum = await _albumRepository.createAlbum(album);

    if (!_controller.isClosed) {
      _controller.add(newAlbum);
    }

    return newAlbum;
  }
}
