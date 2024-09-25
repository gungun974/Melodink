import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/data/datasource/artist_local_data_source.dart';
import 'package:melodink_client/features/library/data/datasource/artist_remote_data_source.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';

class ArtistNotFoundException implements Exception {}

class ArtistRepository {
  final ArtistRemoteDataSource artistRemoteDataSource;
  final ArtistLocalDataSource artistLocalDataSource;

  final NetworkInfo networkInfo;

  ArtistRepository({
    required this.artistRemoteDataSource,
    required this.artistLocalDataSource,
    required this.networkInfo,
  });

  Future<List<Artist>> getAllArtists() async {
    final localArtists = await artistLocalDataSource.getAllArtists();

    if (networkInfo.isServerRecheable()) {
      try {
        final remoteArtists = await artistRemoteDataSource.getAllArtists();

        return remoteArtists;
      } catch (_) {
        return localArtists;
      }
    }

    return await artistLocalDataSource.getAllArtists();
  }

  Future<Artist> getArtistById(String id) async {
    try {
      return await artistRemoteDataSource.getArtistById(id);
    } catch (_) {
      final artist = await artistLocalDataSource.getArtistById(id);

      if (artist == null) {
        throw ArtistNotFoundException();
      }

      return artist;
    }
  }
}

final artistRepositoryProvider = Provider(
  (ref) => ArtistRepository(
    artistRemoteDataSource: ref.watch(
      artistRemoteDataSourceProvider,
    ),
    artistLocalDataSource: ref.watch(
      artistLocalDataSourceProvider,
    ),
    networkInfo: ref.watch(
      networkInfoProvider,
    ),
  ),
);
