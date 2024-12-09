import 'dart:async';
import 'dart:io';

import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_track_provider.g.dart';

@riverpod
class TrackEditStream extends _$TrackEditStream {
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

  void saveTrack(Track track) async {
    final newTrack = await _trackRepository.saveTrack(track);

    if (!_controller.isClosed) {
      _controller.add(newTrack);
    }
  }

  changeTrackAudio(int id, File file) async {
    final newTrack = await _trackRepository.changeTrackAudio(id, file);

    if (!_controller.isClosed) {
      _controller.add(newTrack);
    }
  }
}
