import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/features/library/data/repository/download_album_repository.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';

class DownloadPlaylistRepository {
  final PlaylistRepository playlistRepository;
  final DownloadAlbumRepository downloadAlbumRepository;

  DownloadPlaylistRepository({
    required this.playlistRepository,
    required this.downloadAlbumRepository,
  });

  Future<bool> isPlaylistDownloaded(int id) async {
    final db = await DatabaseService.getDatabase();

    return db.select(
      "SELECT playlist_id FROM playlist_downloads WHERE playlist_id = ?",
      [id],
    ).isNotEmpty;
  }

  Future<void> downloadPlaylist(int id) async {
    final playlist = await playlistRepository.getPlaylistById(id);

    final db = await DatabaseService.getDatabase();

    final result = db.select(
      "SELECT * FROM playlist_downloads WHERE playlist_id = ?",
      [id],
    );

    if (result.isEmpty) {
      db.execute(
        "INSERT OR REPLACE INTO playlist_downloads (playlist_id, cover_file, cover_signature) VALUES (?, NULL, '')",
        [id],
      );
    }

    await _downloadPlaylistCover(playlist);

    for (final track in playlist.tracks) {
      for (final album in track.albums) {
        await downloadAlbumRepository.downloadAlbumPartial(album.id);
      }
    }
  }

  Future<void> _downloadPlaylistCover(Playlist playlist) async {
    final db = await DatabaseService.getDatabase();

    final result = db.select(
      "SELECT cover_file, cover_signature FROM playlist_downloads WHERE playlist_id = ?",
      [playlist.id],
    );

    if (result.isEmpty) {
      return;
    }

    final localFile = result.first;

    if (localFile["cover_signature"] == playlist.coverSignature) {
      return;
    }

    final applicationSupportDirectory =
        (await getMelodinkInstanceSupportDirectory()).path;

    final downloadPath = "/download-playlist/${playlist.id}";

    try {
      final downloadImagePath =
          "$downloadPath/image-${playlist.coverSignature}";

      await AppApi().dio.download(
            "/playlist/${playlist.id}/cover",
            "$applicationSupportDirectory/$downloadImagePath",
          );

      db.execute(
        "UPDATE playlist_downloads SET cover_file = ?, cover_signature = ? WHERE playlist_id = ?",
        [downloadImagePath, playlist.coverSignature, playlist.id],
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
        "UPDATE playlist_downloads SET cover_file = NULL, cover_signature = ? WHERE playlist_id = ?",
        [playlist.coverSignature, playlist.id],
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

  Future<void> freePlaylist(int id) async {
    final db = await DatabaseService.getDatabase();

    final result = db.select(
      "SELECT * FROM playlist_downloads WHERE playlist_id = ?",
      [id],
    );

    if (result.isNotEmpty) {
      db.execute(
        "DELETE FROM playlist_downloads WHERE playlist_id = ?",
        [id],
      );

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
    }

    await downloadAlbumRepository.freeOrphanAlbums();
  }

  Future<void> freeOrphanPlaylists() async {
    final db = await DatabaseService.getDatabase();

    final rows = db.select(
      """
      SELECT playlist_downloads.playlist_id
      FROM playlist_downloads
      WHERE playlist_downloads.playlist_id NOT IN (SELECT playlists.id FROM playlists);
    """,
    );

    for (final row in rows) {
      await freePlaylist(row["playlist_id"]);
    }
  }

  Future<void> freeAllPlaylists() async {
    final db = await DatabaseService.getDatabase();

    final rows = db.select("SELECT playlist_id FROM playlist_downloads");

    for (final row in rows) {
      await freePlaylist(row["playlist_id"]);
    }
  }
}

final downloadPlaylistRepositoryProvider = Provider(
  (ref) => DownloadPlaylistRepository(
    playlistRepository: ref.watch(playlistRepositoryProvider),
    downloadAlbumRepository: ref.watch(downloadAlbumRepositoryProvider),
  ),
);
