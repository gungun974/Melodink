import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_provider.g.dart';

@riverpod
Future<List<Album>> allAlbums(AllAlbumsRef ref) async {
  final albumRepository = ref.read(albumRepositoryProvider);

  return await albumRepository.getAllAlbums();
}

@riverpod
Future<Album> albumById(AlbumByIdRef ref, String id) async {
  final albumRepository = ref.read(albumRepositoryProvider);

  return await albumRepository.getAlbumById(id);
}
