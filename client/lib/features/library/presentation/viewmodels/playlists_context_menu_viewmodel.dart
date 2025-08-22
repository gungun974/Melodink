import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/events/playlist_events.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class PlaylistsContextMenuViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final PlaylistRepository playlistRepository;

  StreamSubscription? _createPlaylistStream;
  StreamSubscription? _editPlaylistStream;
  StreamSubscription? _deletePlaylistStream;

  PlaylistsContextMenuViewModel({
    required this.eventBus,
    required this.playlistRepository,
  }) {
    _createPlaylistStream = eventBus.on<CreatePlaylistEvent>().listen((event) {
      playlists.add(event.createdPlaylist);
      notifyListeners();
    });

    _editPlaylistStream = eventBus.on<EditPlaylistEvent>().listen((event) {
      final index = playlists.indexWhere(
        (playlist) => playlist.id == event.updatedPlaylist.id,
      );

      if (index < 0) {
        return;
      }

      playlists[index] = event.updatedPlaylist;
      notifyListeners();
    });

    _deletePlaylistStream = eventBus.on<DeletePlaylistEvent>().listen((event) {
      playlists = playlists
          .where((playlist) => playlist.id != event.deletedPlaylist.id)
          .toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _createPlaylistStream?.cancel();
    _editPlaylistStream?.cancel();
    _deletePlaylistStream?.cancel();

    super.dispose();
  }

  List<Playlist> playlists = [];

  bool isLoading = false;

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

  Future<void> addTracks(Playlist playlist, List<Track> tracks) async {
    final newPlaylist = await playlistRepository.addPlaylistTracks(
      playlist.id,
      tracks,
    );

    eventBus.fire(EditPlaylistEvent(updatedPlaylist: newPlaylist));
  }

  Future<void> setTracks(Playlist playlist, List<Track> tracks) async {
    final newPlaylist = await playlistRepository.setPlaylistTracks(
      playlist.id,
      tracks,
    );

    eventBus.fire(EditPlaylistEvent(updatedPlaylist: newPlaylist));
  }
}
