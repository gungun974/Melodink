import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artist_provider.g.dart';

@riverpod
Future<List<Artist>> allArtists(AllArtistsRef ref) async {
  final artistRepository = ref.watch(artistRepositoryProvider);

  return await artistRepository.getAllArtists();
}

@riverpod
Future<Artist> artistById(ArtistByIdRef ref, String id) async {
  final artistRepository = ref.watch(artistRepositoryProvider);

  final artist = await artistRepository.getArtistById(id);

  return artist;
}
