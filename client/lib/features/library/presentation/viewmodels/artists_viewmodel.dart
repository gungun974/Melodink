import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/fuzzy_search.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';

enum ArtistsSortMode { nameZA, nameAZ, newest, oldest }

class ArtistsViewModel extends ChangeNotifier {
  final EventBus eventBus;

  final ArtistRepository artistRepository;

  ArtistsViewModel({required this.eventBus, required this.artistRepository});

  bool isLoading = false;

  List<Artist> artists = [];

  List<Artist> searchArtists = [];

  final searchTextController = TextEditingController();

  ArtistsSortMode sortMode = ArtistsSortMode.newest;

  @override
  void dispose() {
    searchTextController.dispose();

    super.dispose();
  }

  Future<void> loadArtists() async {
    isLoading = true;
    artists.clear();
    notifyListeners();

    try {
      artists = await artistRepository.getAllArtists();
      isLoading = false;
      _computeSearchAndSortArtists();

      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void _computeSearchAndSortArtists() {
    switch (sortMode) {
      case ArtistsSortMode.nameZA:
        searchArtists = artists.toList(
          growable: false,
        )..sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ArtistsSortMode.nameAZ:
        searchArtists = artists.toList(
          growable: false,
        )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ArtistsSortMode.newest:
        searchArtists = artists;
        break;
      case ArtistsSortMode.oldest:
        searchArtists = artists.reversed.toList(growable: false);
        break;
    }

    if (searchTextController.text.isEmpty) {
      return;
    }

    searchArtists = artists.where((artist) {
      return compareFuzzySearch(searchTextController.text, artist.name);
    }).toList();
  }

  void updateSearch() {
    _computeSearchAndSortArtists();
    notifyListeners();
  }

  void setSortMode(ArtistsSortMode value) {
    sortMode = value;
    _computeSearchAndSortArtists();
    notifyListeners();
  }
}
