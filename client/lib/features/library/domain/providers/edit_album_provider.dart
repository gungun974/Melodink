import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_album_provider.g.dart';

@riverpod
class EditAlbumStream extends _$EditAlbumStream {
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

  changeAlbumCover(String id, File file) async {
    final newAlbum = await _albumRepository.changeAlbumCover(id, file);

    await ImageCacheManager.clearCache(newAlbum.getOrignalCoverUri());
    await ImageCacheManager.clearCache(
      newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.small),
    );
    await ImageCacheManager.clearCache(
      newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
    );
    await ImageCacheManager.clearCache(
      newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.high),
    );

    PaintingBinding.instance.imageCache.clearLiveImages();
    WidgetsBinding.instance.reassembleApplication();

    if (!_controller.isClosed) {
      _controller.add(newAlbum);
    }
  }

  removeAlbumCover(String id) async {
    final newAlbum = await _albumRepository.removeAlbumCover(id);

    await ImageCacheManager.clearCache(newAlbum.getOrignalCoverUri());
    await ImageCacheManager.clearCache(
      newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.small),
    );
    await ImageCacheManager.clearCache(
      newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
    );
    await ImageCacheManager.clearCache(
      newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.high),
    );

    PaintingBinding.instance.imageCache.clearLiveImages();
    WidgetsBinding.instance.reassembleApplication();

    if (!_controller.isClosed) {
      _controller.add(newAlbum);
    }
  }
}
