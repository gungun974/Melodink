import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_track_provider.g.dart';

class TrackChangeInfo extends Equatable {
  final Track track;
  final bool shouldCheckDownload;

  const TrackChangeInfo({
    required this.track,
    required this.shouldCheckDownload,
  });

  @override
  List<Object?> get props => [
        track,
        shouldCheckDownload,
      ];
}

@riverpod
class TrackEditStream extends _$TrackEditStream {
  late TrackRepository _trackRepository;
  late StreamController<TrackChangeInfo> _controller;

  @override
  Stream<TrackChangeInfo> build() {
    _trackRepository = ref.watch(trackRepositoryProvider);
    _controller = StreamController<TrackChangeInfo>.broadcast();

    ref.onDispose(() {
      _controller.close();
    });

    return _controller.stream;
  }

  void saveTrack(Track track) async {
    final newTrack = await _trackRepository.saveTrack(track);

    if (!_controller.isClosed) {
      _controller.add(
        TrackChangeInfo(
          track: newTrack,
          shouldCheckDownload: false,
        ),
      );
    }
  }

  changeTrackAudio(int id, File file) async {
    final newTrack = await _trackRepository.changeTrackAudio(id, file);

    if (!_controller.isClosed) {
      _controller.add(
        TrackChangeInfo(
          track: newTrack,
          shouldCheckDownload: true,
        ),
      );
    }
  }

  changeTrackCover(int id, File file) async {
    final newTrack = await _trackRepository.changeTrackCover(id, file);

    await AppImageCacheProvider.clearCache(newTrack.getOrignalCoverUri());
    await AppImageCacheProvider.clearCache(
      newTrack.getCompressedCoverUri(TrackCompressedCoverQuality.small),
    );
    await AppImageCacheProvider.clearCache(
      newTrack.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
    );
    await AppImageCacheProvider.clearCache(
      newTrack.getCompressedCoverUri(TrackCompressedCoverQuality.high),
    );

    PaintingBinding.instance.imageCache.clearLiveImages();
    WidgetsBinding.instance.reassembleApplication();

    if (!_controller.isClosed) {
      _controller.add(
        TrackChangeInfo(
          track: newTrack,
          shouldCheckDownload: true,
        ),
      );
    }
  }

  setTrackScore(int id, double score) async {
    final newTrack = await _trackRepository.setTrackScore(id, score);

    if (!_controller.isClosed) {
      _controller.add(
        TrackChangeInfo(
          track: newTrack,
          shouldCheckDownload: false,
        ),
      );
    }
  }
}
