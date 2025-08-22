import 'package:dio/dio.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/sync/data/models/artist_model.dart';
import 'package:melodink_client/features/sync/data/repository/sync_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class ArtistNotFoundException implements Exception {}

class ArtistRepository {
  final SyncRepository syncRepository;

  final NetworkInfo networkInfo;

  ArtistRepository({required this.syncRepository, required this.networkInfo});

  static Artist decodeArtist(Map<String, Object?> data) {
    return Artist(
      id: data["id"] as int,
      name: data["name"] as String,
      albums: [],
      appearAlbums: [],
      hasRoleAlbums: [],
    );
  }

  static void loadArtistAlbums(
    Database db,
    String applicationSupportDirectory,
    Artist artist,
  ) {
    artist.albums
      ..clear()
      ..addAll(
        (db.select(
          '''
        SELECT albums.*, album_downloads.cover_file, album_downloads.album_id as download_id, album_downloads.partial_download
        FROM albums
        LEFT JOIN album_downloads ON album_downloads.album_id = albums.id
        JOIN album_artist ON albums.id = album_artist.album_id
        WHERE album_artist.artist_id = ?
      ''',
          [artist.id],
        )).map(
          (album) =>
              AlbumRepository.decodeAlbum(applicationSupportDirectory, album),
        ),
      );

    for (final artist in artist.albums) {
      AlbumRepository.loadAlbumArtists(db, artist);
    }
  }

  static void loadArtistAppearAlbums(
    Database db,
    String applicationSupportDirectory,
    Artist artist,
  ) {
    artist.appearAlbums
      ..clear()
      ..addAll(
        (db.select(
          '''
    SELECT DISTINCT albums.*, album_downloads.cover_file, album_downloads.album_id as download_id, album_downloads.partial_download
    FROM albums
    LEFT JOIN album_downloads ON album_downloads.album_id = albums.id
    JOIN track_album ON track_album.album_id = albums.id
    JOIN track_artist ON track_artist.track_id = track_album.track_id
    WHERE track_artist.artist_id = ?
      AND NOT EXISTS (
        SELECT 1
        FROM album_artist
        WHERE album_artist.album_id = albums.id
          AND album_artist.artist_id = ?
      )
  ''',
          [artist.id, artist.id],
        )).map(
          (album) =>
              AlbumRepository.decodeAlbum(applicationSupportDirectory, album),
        ),
      );

    for (final album in artist.appearAlbums) {
      AlbumRepository.loadAlbumArtists(db, album);
    }
  }

  Future<List<Artist>> getAllArtists() async {
    try {
      final db = await DatabaseService.getDatabase();

      final artists = (db.select("""
        SELECT *,
          MAX(
              (SELECT MAX(tracks.date_added)
              FROM track_artist
                      JOIN tracks ON tracks.id = track_artist.track_id
              WHERE track_artist.artist_id = artists.id),

              (SELECT MAX(tracks.date_added)
              FROM album_artist
                      JOIN track_album ON track_album.album_id = album_artist.album_id
                      JOIN tracks ON tracks.id = track_album.track_id
              WHERE album_artist.artist_id = artists.id)
          ) AS latest_track_created_at
        FROM artists
        ORDER BY latest_track_created_at DESC
        """)).map(decodeArtist).toList();

      return artists;
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<Artist> getArtistById(int id) async {
    try {
      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final artist = (db.select("SELECT * FROM artists WHERE id = ?", [
        id,
      ])).map(decodeArtist).firstOrNull;

      if (artist == null) {
        throw ArtistNotFoundException();
      }

      loadArtistAlbums(db, applicationSupportDirectory, artist);
      loadArtistAppearAlbums(db, applicationSupportDirectory, artist);

      return artist;
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<Artist> createArtist(Artist artist) async {
    try {
      final response = await AppApi().dio.post(
        "/artist",
        data: {"name": artist.name},
      );

      await syncRepository.performSync();

      return getArtistById(ArtistModel.fromJson(response.data).id);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}
