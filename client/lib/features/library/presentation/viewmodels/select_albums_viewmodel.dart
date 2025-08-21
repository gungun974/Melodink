import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/fuzzy_search.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/presentation/modals/create_album_modal.dart';

class SelectAlbumsViewModel extends ChangeNotifier {
  final EventBus eventBus;

  final AlbumRepository albumRepository;

  SelectAlbumsViewModel({
    required this.eventBus,
    required this.albumRepository,
  });

  bool isLoading = false;

  final searchTextController = TextEditingController();

  List<int> defaultSelectedIds = [];

  List<Album> albums = [];

  List<Album> searchAlbums = [];

  List<int> selectedIds = [];

  @override
  void dispose() {
    searchTextController.dispose();

    super.dispose();
  }

  Future<void> loadAlbums(List<int> defaultSelectedIds) async {
    isLoading = true;

    albums.clear();

    this.defaultSelectedIds = defaultSelectedIds.toList(growable: false);
    selectedIds = defaultSelectedIds.toList();

    notifyListeners();

    try {
      albums = await albumRepository.getAllAlbums();
      isLoading = false;
      _computeSearchAlbums();

      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void _computeSearchAlbums() {
    if (searchTextController.text.isEmpty) {
      searchAlbums = albums;
    } else {
      searchAlbums = albums.where((album) {
        if (selectedIds.contains(album.id)) {
          return true;
        }

        return compareFuzzySearch(searchTextController.text, album.name);
      }).toList();
    }

    searchAlbums.sort(
      (a, b) =>
          (defaultSelectedIds.contains(b.id) ? 1 : 0) -
          (defaultSelectedIds.contains(a.id) ? 1 : 0),
    );
  }

  void updateSearch() {
    _computeSearchAlbums();
    notifyListeners();
  }

  void toggleAlbum(Album album) {
    final index = selectedIds.indexWhere((id) => id == album.id);
    if (index >= 0) {
      selectedIds.clear();
      notifyListeners();
      return;
    }
    selectedIds = [album.id];
    notifyListeners();
  }

  Future<void> createAlbum(BuildContext context) async {
    final album = await CreateAlbumModal.showModal(context);

    if (album == null) {
      return;
    }

    albums.add(album);
    selectedIds.add(album.id);

    _computeSearchAlbums();
    notifyListeners();
  }

  void selectAlbums(BuildContext context) {
    final selectedAlbums = albums
        .where((album) => selectedIds.contains(album.id))
        .toList();

    Navigator.of(context, rootNavigator: true).pop(selectedAlbums);
  }
}
