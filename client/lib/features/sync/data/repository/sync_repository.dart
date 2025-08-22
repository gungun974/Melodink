import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/sync/data/models/album_model.dart';
import 'package:melodink_client/features/sync/data/models/artist_model.dart';
import 'package:melodink_client/features/sync/data/models/playlist_model.dart';
import 'package:melodink_client/features/sync/data/models/sync_modal.dart';
import 'package:melodink_client/features/sync/data/models/track_model.dart';
import 'package:mutex/mutex.dart';
import 'package:sqlite3/sqlite3.dart';

class SyncRepository {
  final NetworkInfo networkInfo;

  SyncRepository({required this.networkInfo});

  //! Tracks

  void _createOrUpdateTracks(Database db, List<TrackModel> tracks) {
    final insert = db.prepare('''
    INSERT OR REPLACE INTO tracks (
      id,
      user_id,
      title,
      duration,
      tags_format,
      file_type,
      file_signature,
      cover_signature,
      track_number,
      disc_number,
      metadata_total_tracks,
      metadata_total_discs,
      metadata_date,
      metadata_year,
      metadata_genres,
      metadata_lyrics,
      metadata_comment,
      metadata_acoust_id,
      metadata_music_brainz_release_id,
      metadata_music_brainz_track_id,
      metadata_music_brainz_recording_id,
      metadata_composer,
      sample_rate,
      bit_rate,
      bits_per_raw_sample,
      score,
      date_added
    ) VALUES (
      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
    );
  ''');

    for (var track in tracks) {
      insert.execute([
        track.id,
        track.userId,
        track.title,
        track.duration.inMilliseconds,
        track.tagsFormat,
        track.fileType,
        track.fileSignature,
        track.coverSignature,
        track.trackNumber,
        track.discNumber,
        track.metadata.totalTracks,
        track.metadata.totalDiscs,
        track.metadata.date,
        track.metadata.year,
        jsonEncode(track.metadata.genres),
        track.metadata.lyrics,
        track.metadata.comment,
        track.metadata.acoustId,
        track.metadata.musicBrainzReleaseId,
        track.metadata.musicBrainzTrackId,
        track.metadata.musicBrainzRecordingId,
        track.metadata.composer,
        track.sampleRate,
        track.bitRate,
        track.bitsPerRawSample,
        track.score,
        track.dateAdded.toIso8601String(),
      ]);
    }

    insert.dispose();
  }

  void _deleteExtraTracks(Database db, List<TrackModel> tracks) {
    final placeholders = List.filled(tracks.length, '?').join(', ');

    final delete = db.prepare(
      "DELETE FROM tracks WHERE id NOT IN ($placeholders)",
    );

    delete.execute(tracks.map((track) => track.id).toList());

    delete.dispose();
  }

  void _deleteTracks(Database db, List<int> tracks) {
    final placeholders = List.filled(tracks.length, '?').join(', ');

    final delete = db.prepare("DELETE FROM tracks WHERE id IN ($placeholders)");

    delete.execute(tracks);

    delete.dispose();
  }

  void _setTrackAlbums(Database db, TrackModel track) {
    if (track.albums.isEmpty) {
      final delete = db.prepare('''
			DELETE FROM track_album
			WHERE track_id = ?
      ''');

      delete.execute([track.id]);

      delete.dispose();

      return;
    }

    // Remove Extra

    final placeholders = List.filled(track.albums.length, '?').join(', ');

    final delete = db.prepare('''
      DELETE FROM track_album
      WHERE track_id = ? AND album_id NOT IN ($placeholders)
      ''');

    delete.execute([track.id, ...track.albums]);

    delete.dispose();

    // Insert Missing

    final placeholders2 = List.filled(
      track.albums.length,
      '(?, ?, ?)',
    ).join(', ');

    final insert = db.prepare('''
      INSERT OR REPLACE INTO track_album (track_id, album_id, album_pos) VALUES $placeholders2
      ''');

    insert.execute(
      List.generate(
        track.albums.length,
        (i) => [track.id, track.albums[i], i],
      ).expand((e) => e).toList(),
    );

    insert.dispose();
  }

  void _setTrackArtists(Database db, TrackModel track) {
    if (track.artists.isEmpty) {
      final delete = db.prepare('''
			DELETE FROM track_artist
			WHERE track_id = ?
      ''');

      delete.execute([track.id]);

      delete.dispose();

      return;
    }

    // Remove Extra

    final placeholders = List.filled(track.artists.length, '?').join(', ');

    final delete = db.prepare('''
      DELETE FROM track_artist
      WHERE track_id = ? AND artist_id NOT IN ($placeholders)
      ''');

    delete.execute([track.id, ...track.artists]);

    delete.dispose();

    // Insert Missing

    final placeholders2 = List.filled(
      track.artists.length,
      '(?, ?, ?)',
    ).join(', ');

    final insert = db.prepare('''
      INSERT OR REPLACE INTO track_artist (track_id, artist_id, artist_pos) VALUES $placeholders2
      ''');

    insert.execute(
      List.generate(
        track.artists.length,
        (i) => [track.id, track.artists[i], i],
      ).expand((e) => e).toList(),
    );

    insert.dispose();
  }

  //! Albums

  void _createOrUpdateAlbums(Database db, List<AlbumModel> albums) {
    final insert = db.prepare('''
      INSERT OR REPLACE INTO albums (
        id,
        user_id,
        name,
        cover_signature
      ) VALUES (
        ?, ?, ?, ?
      );
    ''');

    for (var album in albums) {
      insert.execute([
        album.id,
        album.userId,
        album.name,
        album.coverSignature,
      ]);
    }

    insert.dispose();
  }

  void _deleteExtraAlbums(Database db, List<AlbumModel> albums) {
    final placeholders = List.filled(albums.length, '?').join(', ');

    final delete = db.prepare(
      "DELETE FROM albums WHERE id NOT IN ($placeholders)",
    );

    delete.execute(albums.map((album) => album.id).toList());

    delete.dispose();
  }

  void _deleteAlbums(Database db, List<int> albums) {
    final placeholders = List.filled(albums.length, '?').join(', ');

    final delete = db.prepare("DELETE FROM albums WHERE id IN ($placeholders)");

    delete.execute(albums);

    delete.dispose();
  }

  void _setAlbumArtists(Database db, AlbumModel album) {
    if (album.artists.isEmpty) {
      final delete = db.prepare('''
			DELETE FROM album_artist
			WHERE album_id = ?
      ''');

      delete.execute([album.id]);

      delete.dispose();

      return;
    }

    // Remove Extra

    final placeholders = List.filled(album.artists.length, '?').join(', ');

    final delete = db.prepare('''
      DELETE FROM album_artist
      WHERE album_id = ? AND artist_id NOT IN ($placeholders)
      ''');

    delete.execute([album.id, ...album.artists]);

    delete.dispose();

    // Insert Missing

    final placeholders2 = List.filled(
      album.artists.length,
      '(?, ?, ?)',
    ).join(', ');

    final insert = db.prepare('''
      INSERT OR REPLACE INTO album_artist (album_id, artist_id, artist_pos) VALUES $placeholders2
      ''');

    insert.execute(
      List.generate(
        album.artists.length,
        (i) => [album.id, album.artists[i], i],
      ).expand((e) => e).toList(),
    );

    insert.dispose();
  }

  //! Artists

  void _createOrUpdateArtists(Database db, List<ArtistModel> artists) {
    final insert = db.prepare('''
      INSERT OR REPLACE INTO artists (
        id,
        user_id,
        name
      ) VALUES (
        ?, ?, ?
      );
    ''');

    for (var artist in artists) {
      insert.execute([artist.id, artist.userId, artist.name]);
    }

    insert.dispose();
  }

  void _deleteExtraArtists(Database db, List<ArtistModel> artists) {
    final placeholders = List.filled(artists.length, '?').join(', ');

    final delete = db.prepare(
      "DELETE FROM artists WHERE id NOT IN ($placeholders)",
    );

    delete.execute(artists.map((artist) => artist.id).toList());

    delete.dispose();
  }

  void _deleteArtists(Database db, List<int> artists) {
    final placeholders = List.filled(artists.length, '?').join(', ');

    final delete = db.prepare(
      "DELETE FROM artists WHERE id IN ($placeholders)",
    );

    delete.execute(artists);

    delete.dispose();
  }

  //! Playlists

  void _createOrUpdatePlaylists(Database db, List<PlaylistModel> playlists) {
    final insert = db.prepare('''
      INSERT OR REPLACE INTO playlists (
        id,
        user_id,
        name,
        description,
        cover_signature,
        tracks
      ) VALUES (
        ?, ?, ?, ?, ?, ?
      );
    ''');

    for (var playlist in playlists) {
      insert.execute([
        playlist.id,
        playlist.userId,
        playlist.name,
        playlist.description,
        playlist.coverSignature,
        jsonEncode(playlist.tracks),
      ]);
    }

    insert.dispose();
  }

  void _deleteExtraPlaylists(Database db, List<PlaylistModel> playlists) {
    final placeholders = List.filled(playlists.length, '?').join(', ');

    final delete = db.prepare(
      "DELETE FROM playlists WHERE id NOT IN ($placeholders)",
    );

    delete.execute(playlists.map((playlist) => playlist.id).toList());

    delete.dispose();
  }

  void _deletePlaylists(Database db, List<int> playlists) {
    final placeholders = List.filled(playlists.length, '?').join(', ');

    final delete = db.prepare(
      "DELETE FROM playlists WHERE id IN ($placeholders)",
    );

    delete.execute(playlists);

    delete.dispose();
  }

  //! Sync

  DateTime? _getLastSyncDate(Database db) {
    final result = db.select("SELECT last_sync FROM sync");
    if (result.isEmpty) {
      return null;
    }

    return DateTime.parse(result.first["last_sync"]);
  }

  void _setLastSyncDate(Database db, DateTime date) {
    db.execute("INSERT OR REPLACE INTO sync (id, last_sync) VALUES (1, ?)", [
      date.toIso8601String(),
    ]);
  }

  Future<FullSyncModel> _getFullData() async {
    try {
      final response = await AppApi().dio.get("/sync");

      return FullSyncModel.fromJson(response.data);
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

  Future<void> _performFullSync(Database db) async {
    final data = await _getFullData();

    db.execute('BEGIN;');

    try {
      _createOrUpdateTracks(db, data.tracks);
      _deleteExtraTracks(db, data.tracks);

      _createOrUpdateAlbums(db, data.albums);
      _deleteExtraAlbums(db, data.albums);

      _createOrUpdateArtists(db, data.artists);
      _deleteExtraArtists(db, data.artists);

      _createOrUpdatePlaylists(db, data.playlists);
      _deleteExtraPlaylists(db, data.playlists);

      for (final track in data.tracks) {
        _setTrackAlbums(db, track);
        _setTrackArtists(db, track);
      }

      for (final album in data.albums) {
        _setAlbumArtists(db, album);
      }

      _setLastSyncDate(db, data.date);

      db.execute('COMMIT;');
    } catch (_) {
      db.execute("ROLLBACK;");
      rethrow;
    }
  }

  Future<PartialSyncModel> _getPartialData(DateTime since) async {
    try {
      final response = await AppApi().dio.get(
        "/sync/${since.toIso8601String()}",
      );

      return PartialSyncModel.fromJson(response.data);
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

  Future<void> _performPartialSync(Database db, DateTime since) async {
    final data = await _getPartialData(since);

    db.execute('BEGIN;');

    try {
      _createOrUpdateTracks(db, data.newTracks);
      _deleteTracks(db, data.deletedTracks);

      _createOrUpdateAlbums(db, data.newAlbums);
      _deleteAlbums(db, data.deletedAlbums);

      _createOrUpdateArtists(db, data.newArtists);
      _deleteArtists(db, data.deletedArtists);

      _createOrUpdatePlaylists(db, data.newPlaylists);
      _deletePlaylists(db, data.deletedPlaylists);

      for (final track in data.newTracks) {
        _setTrackAlbums(db, track);
        _setTrackArtists(db, track);
      }

      for (final album in data.newAlbums) {
        _setAlbumArtists(db, album);
      }

      _setLastSyncDate(db, data.date);

      db.execute('COMMIT;');
    } catch (_) {
      db.execute("ROLLBACK;");
      rethrow;
    }
  }

  final _mutex = Mutex();

  Future<void> performSync({bool fullSync = false}) async {
    await _mutex.protect(() async {
      final db = await DatabaseService.getDatabase();

      final date = _getLastSyncDate(db);

      if (date == null || fullSync) {
        final start = DateTime.now();
        syncLogger.i("Start full sync");
        await _performFullSync(db);
        syncLogger.i("Finish full sync in ${DateTime.now().difference(start)}");
        return;
      }

      final start = DateTime.now();
      syncLogger.i("Start partial sync");
      await _performPartialSync(db, date);
      syncLogger.i(
        "Finish partial sync in ${DateTime.now().difference(start)}",
      );
    });
  }
}
