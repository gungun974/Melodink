import 'dart:async';

import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_track_provider.g.dart';

@riverpod
class TrackDeleteStream extends _$TrackDeleteStream {
  late TrackRepository _trackRepository;
  late StreamController<Track> _controller;

  @override
  Stream<Track> build() {
    _trackRepository = ref.watch(trackRepositoryProvider);
    _controller = StreamController<Track>.broadcast();

    ref.onDispose(() {
      _controller.close();
    });

    return _controller.stream;
  }

  deleteTrack(int trackId) async {
    final deletedTrack = await _trackRepository.deleteTrackById(trackId);

    if (!_controller.isClosed) {
      _controller.add(deletedTrack);
    }
  }
}
