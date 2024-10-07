import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'track_provider.g.dart';

@riverpod
Future<List<MinimalTrack>> allTracks(AllTracksRef ref) async {
  final trackRepository = ref.read(trackRepositoryProvider);

  return await trackRepository.getAllTracks();
}

//! Search

final allTracksSearchInputProvider =
    StateProvider.autoDispose<String>((ref) => '');

@riverpod
Future<List<MinimalTrack>> allSearchTracks(AllSearchTracksRef ref) async {
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
Future<List<MinimalArtist>> allTracksArtistFiltersOptions(
    AllTracksArtistFiltersOptionsRef ref) async {
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
Future<List<MinimalTrack>> allFilteredArtistsTracks(
  AllFilteredArtistsTracksRef ref,
) async {
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
Future<List<(String, String)>> allTracksAlbumFiltersOptions(
    AllTracksAlbumFiltersOptionsRef ref) async {
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
Future<List<MinimalTrack>> allFilteredAlbumsTracks(
  AllFilteredAlbumsTracksRef ref,
) async {
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

@Riverpod()
Future<DownloadTrack?> isTrackDownloaded(
  IsTrackDownloadedRef ref,
  int trackId,
) async {
  final downloadTrackRepository = ref.watch(downloadTrackRepositoryProvider);

  return await downloadTrackRepository.getDownloadedTrackByTrackId(trackId);
}
