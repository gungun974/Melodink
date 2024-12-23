import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
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
  Future<List<MinimalTrack>> build() async {
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
          .where(
            (track) => track.id != deletedTrack.id,
          )
          .toList();

      state = AsyncData(updatedTracks);
    });

    return await trackRepository.getAllTracks();
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
          ? newTrack.toMinimalTrack().copyWith(historyInfo: () => info)
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

//! Search

final allTracksSearchInputProvider =
    StateProvider.autoDispose<String>((ref) => '');

@riverpod
Future<List<MinimalTrack>> allSearchTracks(Ref ref) async {
  final allTracks = await ref.watch(allTracksProvider.future);

  final keepAlphanumeric = RegExp(r'[^a-zA-Z0-9]');

  final allTracksSearchInput = ref
      .watch(allTracksSearchInputProvider)
      .toLowerCase()
      .trim()
      .replaceAll(keepAlphanumeric, "");

  if (allTracksSearchInput.isEmpty) {
    return allTracks;
  }

  return allTracks.where((track) {
    if (track.title
        .toLowerCase()
        .replaceAll(keepAlphanumeric, "")
        .contains(allTracksSearchInput)) {
      return true;
    }

    if (track.album
        .toLowerCase()
        .replaceAll(keepAlphanumeric, "")
        .contains(allTracksSearchInput)) {
      return true;
    }

    for (final artist in track.albumArtists) {
      if (artist.name
          .toLowerCase()
          .replaceAll(keepAlphanumeric, "")
          .contains(allTracksSearchInput)) {
        return true;
      }
    }

    for (final artist in track.artists) {
      if (artist.name
          .toLowerCase()
          .replaceAll(keepAlphanumeric, "")
          .contains(allTracksSearchInput)) {
        return true;
      }
    }

    return false;
  }).toList();
}

//! Filter Artists

final allTracksArtistsSelectedOptionsProvider =
    StateProvider.autoDispose<List<String>>((ref) => []);

@riverpod
Future<List<MinimalArtist>> allTracksArtistFiltersOptions(Ref ref) async {
  final allSearchTracks = await ref.watch(allSearchTracksProvider.future);

  final List<MinimalArtist> artists = [];

  void addArtist(MinimalArtist newArtist) {
    for (final artist in artists) {
      if (artist.id == newArtist.id) {
        return;
      }
    }

    artists.add(newArtist);
  }

  for (final track in allSearchTracks) {
    for (final artist in [...track.artists, ...track.albumArtists]) {
      addArtist(artist);
    }
  }

  return artists;
}

@riverpod
Future<List<MinimalTrack>> allFilteredArtistsTracks(Ref ref) async {
  final allSearchTracks = await ref.watch(allSearchTracksProvider.future);

  final allTracksArtistsSelectedOptions =
      ref.watch(allTracksArtistsSelectedOptionsProvider);

  if (allTracksArtistsSelectedOptions.isEmpty) {
    return allSearchTracks;
  }

  final List<MinimalTrack> tracks = [];

  void addTrack(MinimalTrack newTrack) {
    for (final track in tracks) {
      if (track.id == newTrack.id) {
        return;
      }
    }

    tracks.add(newTrack);
  }

  for (final track in allSearchTracks) {
    for (final artist in [...track.artists, ...track.albumArtists]) {
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
    StateProvider.autoDispose<List<String>>((ref) => []);

@riverpod
Future<List<(String, String)>> allTracksAlbumFiltersOptions(Ref ref) async {
  final allFilteredArtistsTracks =
      await ref.watch(allFilteredArtistsTracksProvider.future);

  final List<(String, String)> albums = [];

  void addAlbum((String, String) newAlbum) {
    for (final album in albums) {
      if (album.$1 == newAlbum.$1) {
        return;
      }
    }

    albums.add(newAlbum);
  }

  for (final track in allFilteredArtistsTracks) {
    addAlbum((track.albumId, track.album));
  }

  return albums;
}

@riverpod
Future<List<MinimalTrack>> allFilteredAlbumsTracks(Ref ref) async {
  final allFilteredArtistsTracks =
      await ref.watch(allFilteredArtistsTracksProvider.future);

  final allTracksAlbumsSelectedOptions =
      ref.watch(allTracksAlbumsSelectedOptionsProvider);

  if (allTracksAlbumsSelectedOptions.isEmpty) {
    return allFilteredArtistsTracks;
  }

  final List<MinimalTrack> tracks = [];

  void addTrack(MinimalTrack newTrack) {
    for (final track in tracks) {
      if (track.id == newTrack.id) {
        return;
      }
    }

    tracks.add(newTrack);
  }

  for (final track in allFilteredArtistsTracks) {
    if (allTracksAlbumsSelectedOptions.contains(track.albumId)) {
      addTrack(track);
    }
  }

  if (tracks.isEmpty) {
    ref.read(allTracksAlbumsSelectedOptionsProvider.notifier).state = [];
  }

  return tracks;
}

@riverpod
Future<List<MinimalTrack>> allSortedTracks(Ref ref) async {
  final allFilteredTracks =
      await ref.watch(allFilteredAlbumsTracksProvider.future);

  final tracks = [...allFilteredTracks];

  tracks.sort((a, b) {
    int dateCompare = b.dateAdded.compareTo(a.dateAdded);
    if (dateCompare != 0) {
      return dateCompare;
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

@Riverpod()
Future<DownloadTrack?> isTrackDownloaded(Ref ref, int trackId) async {
  final downloadTrackRepository = ref.watch(downloadTrackRepositoryProvider);

  return await downloadTrackRepository.getDownloadedTrackByTrackId(trackId);
}
