import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/fuzzy_search.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/presentation/modals/create_artist_modal.dart';

class SelectArtistsViewModel extends ChangeNotifier {
  final EventBus eventBus;

  final ArtistRepository artistRepository;

  SelectArtistsViewModel({
    required this.eventBus,
    required this.artistRepository,
  });

  bool isLoading = false;

  final searchTextController = TextEditingController();

  List<int> defaultSelectedIds = [];

  List<Artist> artists = [];

  List<Artist> searchArtists = [];

  List<int> selectedIds = [];

  @override
  void dispose() {
    searchTextController.dispose();

    super.dispose();
  }

  Future<void> loadArtists(List<int> defaultSelectedIds) async {
    isLoading = true;

    artists.clear();

    this.defaultSelectedIds = defaultSelectedIds.toList(growable: false);
    selectedIds = defaultSelectedIds.toList();

    notifyListeners();

    try {
      artists = await artistRepository.getAllArtists();
      isLoading = false;
      _computeSearchArtists();

      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void _computeSearchArtists() {
    if (searchTextController.text.isEmpty) {
      searchArtists = artists;
    } else {
      searchArtists = artists.where((artist) {
        if (selectedIds.contains(artist.id)) {
          return true;
        }

        return compareFuzzySearch(searchTextController.text, artist.name);
      }).toList();
    }

    searchArtists.sort(
      (a, b) =>
          (defaultSelectedIds.contains(b.id) ? 1 : 0) -
          (defaultSelectedIds.contains(a.id) ? 1 : 0),
    );
  }

  void updateSearch() {
    _computeSearchArtists();
    notifyListeners();
  }

  void toggleArtist(Artist artist) {
    final index = selectedIds.indexWhere((id) => id == artist.id);
    if (index >= 0) {
      selectedIds.removeAt(index);
      notifyListeners();
      return;
    }
    selectedIds.add(artist.id);
    notifyListeners();
  }

  Future<void> createArtist(BuildContext context) async {
    final artist = await CreateArtistModal.showModal(context);

    if (artist == null) {
      return;
    }

    artists.add(artist);
    selectedIds.add(artist.id);

    _computeSearchArtists();
    notifyListeners();
  }

  void selectArtists(BuildContext context) {
    final selectedArtists = artists
        .where((album) => selectedIds.contains(album.id))
        .toList();

    Navigator.of(context, rootNavigator: true).pop(selectedArtists);
  }
}
