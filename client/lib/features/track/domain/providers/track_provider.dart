import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/helpers/fuzzy_search.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/providers/delete_track_provider.dart';
import 'package:melodink_client/features/track/domain/providers/edit_track_provider.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'track_provider.g.dart';

@riverpod
class AllTracks extends _$AllTracks {
  late PlayedTrackRepository _playedTrackRepository;

  @override
  Future<List<Track>> build() async {
    final trackRepository = ref.watch(trackRepositoryProvider);
    _playedTrackRepository = ref.watch(playedTrackRepositoryProvider);

    final manager = ref.watch(playerTrackerManagerProvider);

    final subscription = manager.newPlayedTrack.listen((playedTrack) {
      reloadTrackHistoryInfo(playedTrack.trackId);
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    ref.listen(trackEditStreamProvider, (_, rawNewTrack) async {
      final newTrack = rawNewTrack.valueOrNull?.track;

      if (newTrack == null) {
        return;
      }

      await updateTrack(newTrack);
    });

    ref.listen(trackDeleteStreamProvider, (_, rawDeletedTrack) async {
      final deletedTrack = rawDeletedTrack.valueOrNull;

      if (deletedTrack == null) {
        return;
      }

      final tracks = await future;

      final updatedTracks = tracks
          .where((track) => track.id != deletedTrack.id)
          .toList();

      state = AsyncData(updatedTracks);
    });

    final stream = trackRepository.getAllTracks();

    final List<Track> loadedTracks = [];

    stream.listen((newTracks) async {
      loadedTracks.addAll(newTracks);
      state = AsyncData(loadedTracks);
    });

    return loadedTracks;
  }

  reloadTrackHistoryInfo(int trackId) async {
    final info = await _playedTrackRepository.getTrackHistoryInfo(trackId);

    final tracks = await future;

    final updatedTracks = tracks.map((track) {
      return track.id == trackId
          ? track.copyWith(historyInfo: () => info)
          : track;
    }).toList();

    state = AsyncData(updatedTracks);
  }

  updateTrack(Track newTrack) async {
    final info = await _playedTrackRepository.getTrackHistoryInfo(newTrack.id);

    final tracks = await future;

    final updatedTracks = tracks.map((track) {
      return track.id == newTrack.id
          ? newTrack.copyWith(historyInfo: () => info)
          : track;
    }).toList();

    state = AsyncData(updatedTracks);
  }
}

@riverpod
Future<Track> trackById(Ref ref, int id) async {
  final trackRepository = ref.read(trackRepositoryProvider);

  return await trackRepository.getTrackById(id);
}

@riverpod
Future<String> trackLyricsById(Ref ref, int id) async {
  final trackRepository = ref.read(trackRepositoryProvider);

  return await trackRepository.getTrackLyricsById(id);
}

@riverpod
Future<List<Track>> allSortedTracks(Ref ref) async {
  final allTracks = await ref.watch(allTracksProvider.future);

  final tracks = [...allTracks];

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

  return tracks;
}

//! Search

final allTracksSearchInputProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

@riverpod
Future<List<Track>> allSearchTracks(Ref ref) async {
  final allTracks = await ref.watch(allSortedTracksProvider.future);

  final allTracksSearchInput = ref.watch(allTracksSearchInputProvider).trim();

  if (allTracksSearchInput.isEmpty) {
    return allTracks;
  }

  return allTracks.where((track) {
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

    return compareFuzzySearch(allTracksSearchInput, buffer.toString());
  }).toList();
}

//! Filter Artists

final allTracksArtistsSelectedOptionsProvider =
    StateProvider.autoDispose<List<int>>((ref) => []);

@riverpod
Future<List<Artist>> allTracksArtistFiltersOptions(Ref ref) async {
  final allSearchTracks = await ref.watch(allSearchTracksProvider.future);

  final List<Artist> artists = [];

  void addArtist(Artist newArtist) {
    for (final artist in artists) {
      if (artist.id == newArtist.id) {
        return;
      }
    }

    artists.add(newArtist);
  }

  for (final track in allSearchTracks) {
    for (final artist in [
      ...track.artists,
      ...track.albums.fold([], (acc, value) {
        return [...acc, ...value.artists];
      }),
    ]) {
      addArtist(artist);
    }
  }

  return artists;
}

@riverpod
Future<List<Track>> allFilteredArtistsTracks(Ref ref) async {
  final allSearchTracks = await ref.watch(allSearchTracksProvider.future);

  final allTracksArtistsSelectedOptions = ref.watch(
    allTracksArtistsSelectedOptionsProvider,
  );

  if (allTracksArtistsSelectedOptions.isEmpty) {
    return allSearchTracks;
  }

  final List<Track> tracks = [];

  void addTrack(Track newTrack) {
    for (final track in tracks) {
      if (track.id == newTrack.id) {
        return;
      }
    }

    tracks.add(newTrack);
  }

  for (final track in allSearchTracks) {
    for (final artist in [
      ...track.artists,
      ...track.albums.fold([], (acc, value) {
        return [...acc, ...value.artists];
      }),
    ]) {
      if (allTracksArtistsSelectedOptions.contains(artist.id)) {
        addTrack(track);
        break;
      }
    }
  }

  if (tracks.isEmpty) {
    ref.read(allTracksArtistsSelectedOptionsProvider.notifier).state = [];
  }

  return tracks;
}

//! Filter Albums

final allTracksAlbumsSelectedOptionsProvider =
    StateProvider.autoDispose<List<int>>((ref) => []);

@riverpod
Future<List<(int, String)>> allTracksAlbumFiltersOptions(Ref ref) async {
  final allFilteredArtistsTracks = await ref.watch(
    allFilteredArtistsTracksProvider.future,
  );

  final List<(int, String)> albums = [];

  void addAlbum((int, String) newAlbum) {
    for (final album in albums) {
      if (album.$1 == newAlbum.$1) {
        return;
      }
    }

    albums.add(newAlbum);
  }

  for (final track in allFilteredArtistsTracks) {
    for (final album in track.albums) {
      addAlbum((album.id, album.name));
    }
  }

  return albums;
}

@riverpod
Future<List<Track>> allFilteredAlbumsTracks(Ref ref) async {
  final allFilteredArtistsTracks = await ref.watch(
    allFilteredArtistsTracksProvider.future,
  );

  final allTracksAlbumsSelectedOptions = ref.watch(
    allTracksAlbumsSelectedOptionsProvider,
  );

  if (allTracksAlbumsSelectedOptions.isEmpty) {
    return allFilteredArtistsTracks;
  }

  final List<Track> tracks = [];

  void addTrack(Track newTrack) {
    for (final track in tracks) {
      if (track.id == newTrack.id) {
        return;
      }
    }

    tracks.add(newTrack);
  }

  for (final track in allFilteredArtistsTracks) {
    for (final album in track.albums) {
      if (allTracksAlbumsSelectedOptions.contains(album.id)) {
        addTrack(track);
      }
    }
  }

  if (tracks.isEmpty) {
    ref.read(allTracksAlbumsSelectedOptionsProvider.notifier).state = [];
  }

  return tracks;
}

@Riverpod()
Future<DownloadTrack?> isTrackDownloaded(Ref ref, int trackId) async {
  final downloadTrackRepository = ref.watch(downloadTrackRepositoryProvider);

  return await downloadTrackRepository.getDownloadedTrackByTrackId(trackId);
}
