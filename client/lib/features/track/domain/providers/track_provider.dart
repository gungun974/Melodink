import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final allTracksSearchInputProvider = StateProvider<String>((ref) => '');

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

@Riverpod()
Future<DownloadTrack?> isTrackDownloaded(
  IsTrackDownloadedRef ref,
  int trackId,
) async {
  final downloadTrackRepository = ref.watch(downloadTrackRepositoryProvider);

  return await downloadTrackRepository.getDownloadedTrackByTrackId(trackId);
}
