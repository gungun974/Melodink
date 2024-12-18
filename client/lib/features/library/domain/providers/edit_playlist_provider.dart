import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_playlist_provider.g.dart';

@riverpod
class EditPlaylistStream extends _$EditPlaylistStream {
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

  Future<Playlist> savePlaylist(Playlist playlist) async {
    final newPlaylist = await _playlistRepository.savePlaylist(playlist);

    if (!_controller.isClosed) {
      _controller.add(newPlaylist);
    }

    return newPlaylist;
  }

  changePlaylistCover(int id, File file) async {
    final newPlaylist = await _playlistRepository.changePlaylistCover(id, file);

    await AppImageCacheProvider.clearCache(newPlaylist.getOrignalCoverUri());
    await AppImageCacheProvider.clearCache(
      newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.small),
    );
    await AppImageCacheProvider.clearCache(
      newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
    );
    await AppImageCacheProvider.clearCache(
      newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.high),
    );

    PaintingBinding.instance.imageCache.clearLiveImages();
    WidgetsBinding.instance.reassembleApplication();

    if (!_controller.isClosed) {
      _controller.add(newPlaylist);
    }
  }

  removePlaylistCover(int id) async {
    final newPlaylist = await _playlistRepository.removePlaylistCover(id);

    if (!_controller.isClosed) {
      _controller.add(newPlaylist);
    }
  }
}
