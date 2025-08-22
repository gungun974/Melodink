import 'dart:io';

import 'package:dio/dio.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:sqlite3/sqlite3.dart';

class DownloadAlbumRepository {
  final AlbumRepository albumRepository;

  DownloadAlbumRepository({required this.albumRepository});

  Future<bool> isAlbumDownloaded(int id) async {
    final db = await DatabaseService.getDatabase();

    return db.select(
      "SELECT album_id FROM album_downloads WHERE album_id = ? AND partial_download = FALSE",
      [id],
    ).isNotEmpty;
  }

  Future<void> downloadAlbum(int id) async {
    final album = await albumRepository.getAlbumById(id);

    final db = await DatabaseService.getDatabase();

    final result = db.select(
      "SELECT * FROM album_downloads WHERE album_id = ?",
      [id],
    );

    if (result.isNotEmpty) {
      db.execute(
        "UPDATE album_downloads SET partial_download = FALSE WHERE album_id = ?",
        [id],
      );
    } else {
      db.execute(
        "INSERT OR REPLACE INTO album_downloads (album_id, cover_file, cover_signature, partial_download) VALUES (?, NULL, '', FALSE)",
        [id],
      );
    }

    await _downloadAlbumCover(album);
  }

  Future<void> downloadAlbumPartial(int id) async {
    final album = await albumRepository.getAlbumById(id);

    final db = await DatabaseService.getDatabase();

    final result = db.select(
      "SELECT * FROM album_downloads WHERE album_id = ?",
      [id],
    );

    if (result.isEmpty) {
      db.execute(
        "INSERT OR REPLACE INTO album_downloads (album_id, cover_file, cover_signature, partial_download) VALUES (?, NULL, '', TRUE)",
        [id],
      );
    }

    await _downloadAlbumCover(album);
  }

  Future<void> _downloadAlbumCover(Album album) async {
    final db = await DatabaseService.getDatabase();

    final result = db.select(
      "SELECT cover_file, cover_signature FROM album_downloads WHERE album_id = ?",
      [album.id],
    );

    if (result.isEmpty) {
      return;
    }

    final localFile = result.first;

    if (localFile["cover_signature"] == album.coverSignature) {
      return;
    }

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    final downloadPath = "/download-album/${album.id}";

    try {
      final downloadImagePath = "$downloadPath/image-${album.coverSignature}";

      await AppApi().dio.download(
        "/album/${album.id}/cover",
        "$applicationSupportDirectory/$downloadImagePath",
      );

      db.execute(
        "UPDATE album_downloads SET cover_file = ?, cover_signature = ? WHERE album_id = ?",
        [downloadImagePath, album.coverSignature, album.id],
      );

      if (localFile["cover_file"] != null) {
        try {
          await File(
            "$applicationSupportDirectory/${localFile["cover_file"]}",
          ).delete();
        } catch (_) {}
      }
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        rethrow;
      }

      if (response.statusCode != 404) {
        rethrow;
      }

      db.execute(
        "UPDATE album_downloads SET cover_file = NULL, cover_signature = ? WHERE album_id = ?",
        [album.coverSignature, album.id],
      );

      if (localFile["cover_file"] != null) {
        try {
          await File(
            "$applicationSupportDirectory/${localFile["cover_file"]}",
          ).delete();
        } catch (_) {}
      }
    }
  }

  Future<bool> freeAlbum(int id) async {
    final db = await DatabaseService.getDatabase();

    final result = db.select(
      "SELECT * FROM album_downloads WHERE album_id = ?",
      [id],
    );

    if (result.isEmpty) {
      return false;
    }

    if (_shouldAlbumBePartial(db, id)) {
      db.execute(
        "UPDATE album_downloads SET partial_download = TRUE WHERE album_id = ?",
        [id],
      );
      return true;
    }

    db.execute("DELETE FROM album_downloads WHERE album_id = ?", [id]);

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    final localFile = result.first;

    if (localFile["cover_file"] != null) {
      try {
        await File(
          "$applicationSupportDirectory/${localFile["cover_file"]}",
        ).delete();
      } catch (_) {}
    }

    return false;
  }

  Future<void> freeOrphanAlbums() async {
    final db = await DatabaseService.getDatabase();

    final rows = db.select("""
      SELECT album_downloads.album_id
      FROM album_downloads
      WHERE (album_downloads.album_id NOT IN (SELECT track_album.album_id
                                              FROM playlist_downloads
                                                      JOIN playlists ON playlist_downloads.playlist_id = playlists.id
                                                      JOIN json_each(playlists.tracks) AS je ON TRUE
                                                      JOIN track_album ON track_album.track_id = je.value)
          AND album_downloads.partial_download = TRUE)
        OR (album_downloads.album_id NOT IN (SELECT albums.id FROM albums));
    """);

    for (final row in rows) {
      await freeAlbum(row["album_id"]);
    }
  }

  bool _shouldAlbumBePartial(Database db, int albumId) {
    return db
        .select(
          """
      SELECT DISTINCT track_album.album_id
      FROM playlist_downloads
              JOIN playlists ON playlist_downloads.playlist_id = playlists.id
              JOIN json_each(playlists.tracks) AS je
                    ON TRUE
              JOIN track_album
                    ON track_album.track_id = je.value
      WHERE track_album.album_id = ?;
    """,
          [albumId],
        )
        .isNotEmpty;
  }

  Future<void> freeAllAlbums() async {
    final db = await DatabaseService.getDatabase();

    final rows = db.select("SELECT album_id FROM album_downloads");

    for (final row in rows) {
      await freeAlbum(row["album_id"]);
    }
  }
}
