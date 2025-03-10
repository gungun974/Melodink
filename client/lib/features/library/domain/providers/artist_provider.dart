import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/fuzzy_search.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artist_provider.g.dart';

//! Artists

@riverpod
Future<List<Artist>> allArtists(Ref ref) async {
  final artistRepository = ref.watch(artistRepositoryProvider);

  return await artistRepository.getAllArtists();
}

final allArtistsSortedModeProvider =
    StateProvider.autoDispose<String>((ref) => 'newest');

final allArtistsSearchInputProvider =
    StateProvider.autoDispose<String>((ref) => '');

@riverpod
Future<List<Artist>> allArtistsSorted(Ref ref) async {
  final allArtists = await ref.watch(allArtistsProvider.future);

  final sortedMode = ref.watch(allArtistsSortedModeProvider);

  return allArtists.toList(growable: false)
    ..sort(
      (a, b) {
        return switch (sortedMode) {
          // Name Z-A
          "name-za" => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          // Name A-Z
          "name-az" => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          // Oldest
          "oldest" => a.lastTrackDateAdded.compareTo(b.lastTrackDateAdded),
          // Newest
          _ => b.lastTrackDateAdded.compareTo(a.lastTrackDateAdded),
        };
      },
    );
}

@riverpod
Future<List<Artist>> allSearchArtists(Ref ref) async {
  final allArtists = await ref.watch(allArtistsSortedProvider.future);

  final allArtistsSearchInput = ref.watch(allArtistsSearchInputProvider).trim();

  if (allArtistsSearchInput.isEmpty) {
    return allArtists;
  }

  return allArtists.where((artist) {
    return compareFuzzySearch(allArtistsSearchInput, artist.name);
  }).toList();
}

//! Artist Page

@riverpod
Future<Artist> artistById(Ref ref, String id) async {
  final artistRepository = ref.watch(artistRepositoryProvider);

  final artist = await artistRepository.getArtistById(id);

  return artist;
}
