import 'dart:async';

import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_artist_provider.g.dart';

@riverpod
class CreateArtistStream extends _$CreateArtistStream {
  late ArtistRepository _artistRepository;
  late StreamController<Artist> _controller;

  @override
  Stream<Artist> build() {
    _artistRepository = ref.watch(artistRepositoryProvider);
    _controller = StreamController<Artist>.broadcast();

    ref.onDispose(() {
      _controller.close();
    });

    return _controller.stream;
  }

  Future<Artist> createArtist(Artist artist) async {
    final newArtist = await _artistRepository.createArtist(artist);

    if (!_controller.isClosed) {
      _controller.add(newArtist);
    }

    return newArtist;
  }
}
