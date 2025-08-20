import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';

class PlaylistsViewModel extends ChangeNotifier {
  bool isLoading = false;

  List<Playlist> playlists = [];

  final EventBus eventBus;

  final PlaylistRepository playlistRepository;

  PlaylistsViewModel({
    required this.eventBus,
    required this.playlistRepository,
  });

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
