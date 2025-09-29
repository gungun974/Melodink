import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/domain/events/album_events.dart';

class ArtistViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final ArtistRepository artistRepository;

  StreamSubscription? _editAlbumStream;
  StreamSubscription? _deleteAlbumStream;

  ArtistViewModel({required this.eventBus, required this.artistRepository}) {
    _editAlbumStream = eventBus.on<EditAlbumEvent>().listen((event) {
      final artist = this.artist;

      if (artist == null) {
        return;
      }

      this.artist = artist.copyWith(
        albums: artist.albums
            .map(
              (album) => album.id == event.updatedAlbum.id
                  ? event.updatedAlbum
                  : album,
            )
            .toList(),
        appearAlbums: artist.appearAlbums
            .map(
              (album) => album.id == event.updatedAlbum.id
                  ? event.updatedAlbum
                  : album,
            )
            .toList(),
        hasRoleAlbums: artist.hasRoleAlbums
            .map(
              (album) => album.id == event.updatedAlbum.id
                  ? event.updatedAlbum
                  : album,
            )
            .toList(),
      );

      notifyListeners();
    });

    _deleteAlbumStream = eventBus.on<DeleteAlbumEvent>().listen((event) {
      final artist = this.artist;

      if (artist == null) {
        return;
      }

      this.artist = artist.copyWith(
        albums: artist.albums
            .where((album) => album.id != event.deletedAlbum.id)
            .toList(),
        appearAlbums: artist.appearAlbums
            .where((album) => album.id != event.deletedAlbum.id)
            .toList(),
        hasRoleAlbums: artist.hasRoleAlbums
            .where((album) => album.id != event.deletedAlbum.id)
            .toList(),
      );

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _editAlbumStream?.cancel();
    _deleteAlbumStream?.cancel();

    super.dispose();
  }

  bool isLoading = false;

  Artist? artist;

  Future<void> loadArtist(int id) async {
    isLoading = true;
    notifyListeners();

    try {
      artist = await artistRepository.getArtistById(id);

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }
}
