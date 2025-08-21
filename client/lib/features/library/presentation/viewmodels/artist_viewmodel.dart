import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';

class ArtistViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final ArtistRepository artistRepository;

  ArtistViewModel({required this.eventBus, required this.artistRepository});

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
