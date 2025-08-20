import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/fuzzy_search.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/events/track_events.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class TracksViewModel extends ChangeNotifier {
  bool isLoading = false;

  List<Track> tracks = [];

  List<Track> searchTracks = [];

  final TextEditingController searchTextController = TextEditingController();

  final EventBus eventBus;

  final AudioController audioController;

  final TrackRepository trackRepository;

  StreamSubscription? _editTrackStream;
  StreamSubscription? _deleteTrackStream;

  TracksViewModel({
    required this.eventBus,
    required this.audioController,
    required this.trackRepository,
  }) {
    _editTrackStream = eventBus.on<EditTrackEvent>().listen((event) {
      final index = tracks.indexWhere(
        (track) => track.id == event.updatedTrack.id,
      );

      if (index < 0) {
        return;
      }

      tracks[index] = event.updatedTrack;

      _computeSearchTracks();
      notifyListeners();
    });

    _deleteTrackStream = eventBus.on<DeleteTrackEvent>().listen((event) {
      tracks = tracks
          .where((track) => track.id != event.deletedTrack.id)
          .toList();
      _computeSearchTracks();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    searchTextController.dispose();

    _editTrackStream?.cancel();
    _deleteTrackStream?.cancel();

    super.dispose();
  }

  void loadTracks() {
    final stream = trackRepository.getAllTracks();

    isLoading = true;
    tracks.clear();
    _computeSearchTracks();
    notifyListeners();

    stream.listen(
      (newTracks) async {
        tracks.addAll(newTracks);
        _sortTracks();
        _computeSearchTracks();
        notifyListeners();
      },
      onDone: () {
        isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void _sortTracks() {
    tracks.sort((a, b) {
      int dateCompare = b.dateAdded.compareTo(a.dateAdded);
      if (dateCompare != 0) {
        return dateCompare;
      }

      int albumCompare = a.albums
          .map((album) => album.name + album.id.toString())
          .join(",")
          .compareTo(
            b.albums.map((album) => album.name + album.id.toString()).join(","),
          );
      if (albumCompare != 0) {
        return albumCompare;
      }

      int discCompare = a.discNumber.compareTo(b.discNumber);
      if (discCompare != 0) {
        return discCompare;
      }

      int trackCompare = a.trackNumber.compareTo(b.trackNumber);
      if (trackCompare != 0) {
        return trackCompare;
      }

      return a.title.compareTo(b.title);
    });
  }

  void _computeSearchTracks() {
    if (searchTextController.text.isEmpty) {
      searchTracks = tracks;
      return;
    }

    searchTracks = tracks.where((track) {
      final buffer = StringBuffer();

      buffer.write(track.title);

      for (final album in track.albums) {
        buffer.write(album.name);

        for (final artist in album.artists) {
          buffer.write(artist.name);
        }
      }

      for (final artist in track.artists) {
        buffer.write(artist.name);
      }

      return compareFuzzySearch(searchTextController.text, buffer.toString());
    }).toList();
  }

  void updateSearch() {
    _computeSearchTracks();
    notifyListeners();
  }

  void clearSearch() {
    searchTextController.clear();
    _computeSearchTracks();
    notifyListeners();
  }

  void playTrack(Track track) async {
    if (isLoading) {
      return;
    }

    final index = tracks.indexWhere((trackd) => trackd.id == track.id);

    if (index < 0) {
      return;
    }

    await audioController.loadTracks(
      tracks,
      startAt: index,
      source: t.general.playingFromAllTracks,
    );
  }
}
