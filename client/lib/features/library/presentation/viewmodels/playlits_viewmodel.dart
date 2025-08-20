import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/events/playlist_events.dart';

class PlaylistsViewModel extends ChangeNotifier {
  bool isLoading = false;

  List<Playlist> playlists = [];

  final EventBus eventBus;

  final PlaylistRepository playlistRepository;

  StreamSubscription? _createPlaylistStream;

  PlaylistsViewModel({
    required this.eventBus,
    required this.playlistRepository,
  }) {
    _createPlaylistStream = eventBus.on<CreatePlaylistEvent>().listen((event) {
      playlists.add(event.createdPlaylist);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _createPlaylistStream?.cancel();

    super.dispose();
  }

  Future<void> loadPlaylists() async {
    isLoading = true;
    playlists.clear();
    notifyListeners();

    try {
      playlists = await playlistRepository.getAllPlaylists();
      isLoading = false;

      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }
}
