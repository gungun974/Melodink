import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/fuzzy_search.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/domain/events/album_events.dart';

enum AlbumsSortMode { artistZA, artistAZ, nameZA, nameAZ, newest, oldest }

class AlbumsViewModel extends ChangeNotifier {
  final EventBus eventBus;

  final AlbumRepository albumRepository;

  StreamSubscription? _createAlbumStream;
  StreamSubscription? _editAlbumStream;
  StreamSubscription? _deleteAlbumStream;

  AlbumsViewModel({required this.eventBus, required this.albumRepository}) {
    _createAlbumStream = eventBus.on<CreateAlbumEvent>().listen((event) {
      albums.add(event.createdAlbum);
      notifyListeners();
    });

    _editAlbumStream = eventBus.on<EditAlbumEvent>().listen((event) {
      final index = albums.indexWhere(
        (album) => album.id == event.updatedAlbum.id,
      );

      if (index < 0) {
        return;
      }

      albums[index] = event.updatedAlbum;
      notifyListeners();
    });

    _deleteAlbumStream = eventBus.on<DeleteAlbumEvent>().listen((event) {
      albums = albums
          .where((album) => album.id != event.deletedAlbum.id)
          .toList();
      notifyListeners();
    });
  }

  bool isLoading = false;

  List<Album> albums = [];

  List<Album> searchAlbums = [];

  final searchTextController = TextEditingController();

  AlbumsSortMode sortMode = AlbumsSortMode.newest;

  @override
  void dispose() {
    _createAlbumStream?.cancel();
    _editAlbumStream?.cancel();
    _deleteAlbumStream?.cancel();

    searchTextController.dispose();

    super.dispose();
  }

  Future<void> loadAlbums() async {
    if (isLoading) {
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      albums = await albumRepository.getAllAlbums();
      isLoading = false;
      _computeSearchAndSortAlbums();

      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void _computeSearchAndSortAlbums() {
    switch (sortMode) {
      case AlbumsSortMode.artistZA:
        searchAlbums = albums.toList(growable: false)
          ..sort((a, b) => compareArtists(b.artists, a.artists));
        break;
      case AlbumsSortMode.artistAZ:
        searchAlbums = albums.toList(growable: false)
          ..sort((a, b) => compareArtists(a.artists, b.artists));
        break;
      case AlbumsSortMode.nameZA:
        searchAlbums = albums.toList(
          growable: false,
        )..sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case AlbumsSortMode.nameAZ:
        searchAlbums = albums.toList(
          growable: false,
        )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case AlbumsSortMode.newest:
        searchAlbums = albums;
        break;
      case AlbumsSortMode.oldest:
        searchAlbums = albums.reversed.toList(growable: false);
        break;
    }

    if (searchTextController.text.isEmpty) {
      return;
    }

    searchAlbums = albums.where((album) {
      final buffer = StringBuffer();

      buffer.write(album.name);

      for (final artist in album.artists) {
        buffer.write(artist.name);
      }

      return compareFuzzySearch(searchTextController.text, buffer.toString());
    }).toList();
  }

  void updateSearch() {
    _computeSearchAndSortAlbums();
    notifyListeners();
  }

  void setSortMode(AlbumsSortMode value) {
    sortMode = value;
    _computeSearchAndSortAlbums();
    notifyListeners();
  }
}

int compareArtists(List<Artist> a, List<Artist> b) {
  int minLength = a.length < b.length ? a.length : b.length;

  for (int i = 0; i < minLength; i++) {
    if (a[i].name.isEmpty && b[i].name.isNotEmpty) {
      return 1;
    }

    if (b[i].name.isEmpty && a[i].name.isNotEmpty) {
      return -1;
    }

    int comparison = a[i].name.toLowerCase().compareTo(b[i].name.toLowerCase());
    if (comparison != 0) {
      return comparison;
    }
  }

  return a.length.compareTo(b.length);
}
