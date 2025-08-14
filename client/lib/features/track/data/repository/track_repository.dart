import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/sync/data/models/track_model.dart';
import 'package:melodink_client/features/sync/data/repository/sync_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class TrackNotFoundException implements Exception {}

class TrackRepository {
  final PlayedTrackRepository playedTrackRepository;
  final SyncRepository syncRepository;

  final NetworkInfo networkInfo;

  TrackRepository({
    required this.playedTrackRepository,
    required this.syncRepository,
    required this.networkInfo,
  });

  static Track decodeTrack(
    Map<String, Object?> data,
  ) {
    return Track(
      id: data["id"] as int,
      title: data["title"] as String,
      duration: Duration(milliseconds: data["duration"] as int),
      tagsFormat: data["tags_format"] as String,
      fileType: data["file_type"] as String,
      fileSignature: data["file_signature"] as String,
      coverSignature: data["cover_signature"] as String,
      albums: [],
      artists: [],
      trackNumber: data["track_number"] as int,
      discNumber: data["disc_number"] as int,
      metadata: TrackMetadata(
        totalTracks: data["metadata_total_tracks"] as int,
        totalDiscs: data["metadata_total_discs"] as int,
        date: data["metadata_date"] as String,
        year: data["metadata_year"] as int,
        genres: List.from(jsonDecode(data["metadata_genres"] as String)),
        lyrics: data["metadata_lyrics"] as String,
        comment: data["metadata_comment"] as String,
        acoustId: data["metadata_acoust_id"] as String,
        musicBrainzReleaseId:
            data["metadata_music_brainz_release_id"] as String,
        musicBrainzTrackId: data["metadata_music_brainz_track_id"] as String,
        musicBrainzRecordingId:
            data["metadata_music_brainz_recording_id"] as String,
        composer: data["metadata_composer"] as String,
      ),
      sampleRate: data["sample_rate"] as int,
      bitRate: data["bit_rate"] as int?,
      bitsPerRawSample: data["bits_per_raw_sample"] as int?,
      dateAdded: DateTime.parse(data["date_added"] as String),
      score: data["score"] as double,
    );
  }

  static Track decodeOnlineTrack(
    Database db,
    String applicationSupportDirectory,
    dynamic rawModel,
  ) {
    final track = TrackModel.fromJson(rawModel);

    final albums = db
        .select(
          "SELECT albums.*, album_downloads.cover_file, album_downloads.album_id as download_id, album_downloads.partial_download FROM albums LEFT JOIN album_downloads ON album_downloads.album_id = albums.id WHERE id IN (${List.filled(track.albums.length, '?').join(', ')})",
          track.albums,
        )
        .map(
          (album) => AlbumRepository.decodeAlbum(
            applicationSupportDirectory,
            album,
          ),
        )
        .toList();

    for (final album in albums) {
      AlbumRepository.loadAlbumArtists(db, album);
    }

    final artists = db
        .select(
          "SELECT * FROM artists WHERE id IN (${List.filled(track.artists.length, '?').join(', ')})",
          track.artists,
        )
        .map(ArtistRepository.decodeArtist)
        .toList();

    return Track(
      id: track.id,
      title: track.title,
      duration: track.duration,
      tagsFormat: track.tagsFormat,
      fileType: track.fileType,
      fileSignature: track.fileSignature,
      coverSignature: track.coverSignature,
      albums: albums,
      artists: artists,
      trackNumber: track.trackNumber,
      discNumber: track.discNumber,
      metadata: TrackMetadata(
        totalTracks: track.metadata.totalTracks,
        totalDiscs: track.metadata.totalDiscs,
        date: track.metadata.date,
        year: track.metadata.year,
        genres: track.metadata.genres,
        lyrics: track.metadata.lyrics,
        comment: track.metadata.comment,
        acoustId: track.metadata.acoustId,
        musicBrainzReleaseId: track.metadata.musicBrainzReleaseId,
        musicBrainzTrackId: track.metadata.musicBrainzTrackId,
        musicBrainzRecordingId: track.metadata.musicBrainzRecordingId,
        composer: track.metadata.comment,
      ),
      sampleRate: track.sampleRate,
      bitRate: track.bitRate,
      bitsPerRawSample: track.bitsPerRawSample,
      dateAdded: track.dateAdded,
      score: track.score,
    );
  }

  static loadTrackAlbums(
    Database db,
    String applicationSupportDirectory,
    Track track,
  ) {
    track.albums
      ..clear()
      ..addAll(
        (db.select('''
        SELECT albums.*, album_downloads.cover_file, album_downloads.album_id as download_id, album_downloads.partial_download
        FROM albums
        LEFT JOIN album_downloads ON album_downloads.album_id = albums.id
        JOIN track_album ON albums.id = track_album.album_id
        WHERE track_album.track_id = ?
	    	ORDER BY track_album.album_pos ASC
      ''', [track.id])).map(
          (album) => AlbumRepository.decodeAlbum(
            applicationSupportDirectory,
            album,
          ),
        ),
      );

    for (final album in track.albums) {
      AlbumRepository.loadAlbumArtists(db, album);
    }
  }

  static loadTrackArtists(Database db, Track track) {
    track.artists
      ..clear()
      ..addAll(
        (db.select('''
        SELECT * FROM artists
        JOIN track_artist ON artists.id = track_artist.artist_id
        WHERE track_artist.track_id = ?
	    	ORDER BY track_artist.artist_pos ASC
      ''', [track.id])).map(ArtistRepository.decodeArtist),
      );
  }

  Stream<List<Track>> getAllTracks() async* {
    try {
      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final tracks =
          (db.select("SELECT * FROM tracks")).map(decodeTrack).toList();

      await playedTrackRepository.loadTrackHistoryIntoTracks(tracks);

      const chunkSize = 1000;

      for (var i = tracks.length; i > 0; i -= chunkSize) {
        final start = (i - chunkSize < 0) ? 0 : i - chunkSize;
        var chunk = tracks.sublist(start, i);

        for (final track in chunk) {
          loadTrackAlbums(db, applicationSupportDirectory, track);
          loadTrackArtists(db, track);
        }

        yield chunk;
        await Future.delayed(Duration(milliseconds: 1));
      }
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<List<Track>> getAllPendingImportTracks() async {
    try {
      final response = await AppApi().dio.get("/track/import");

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return (response.data as List)
          .map((rawModel) =>
              decodeOnlineTrack(db, applicationSupportDirectory, rawModel))
          .toList();
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

  Future<Track> getTrackById(int id) async {
    try {
      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final track = (db.select("SELECT * FROM tracks WHERE id = ?", [id]))
          .map(decodeTrack)
          .firstOrNull;

      if (track == null) {
        throw TrackNotFoundException();
      }

      final info = await playedTrackRepository.getTrackHistoryInfo(id);

      loadTrackAlbums(db, applicationSupportDirectory, track);
      loadTrackArtists(db, track);

      return track.copyWith(
        historyInfo: () => info,
      );
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<Track> getTrackByIdOnline(int id) async {
    try {
      final response = await AppApi().dio.get("/track/$id");

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
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

  Future<String> getTrackLyricsById(int id) async {
    try {
      final db = await DatabaseService.getDatabase();

      final track =
          (db.select("SELECT metadata_lyrics FROM tracks WHERE id = ?", [id]))
              .firstOrNull;

      if (track == null) {
        throw TrackNotFoundException();
      }

      return track["metadata_lyrics"] as String;
    } catch (e) {
      mainLogger.e(e);
      rethrow;
    }
  }

  Future<Track> saveTrack(Track track) async {
    try {
      final response = await AppApi().dio.put(
        "/track/${track.id}",
        data: {
          "id": track.id,
          "title": track.title,
          "track_number": track.trackNumber,
          "total_tracks": track.metadata.totalTracks,
          "disc_number": track.discNumber,
          "total_discs": track.metadata.totalDiscs,
          "date": track.metadata.date,
          "year": track.metadata.year,
          "genres": track.metadata.genres,
          "lyrics": track.metadata.lyrics,
          "comment": track.metadata.comment,
          "composer": track.metadata.composer,
          "acoust_id": track.metadata.acoustId,
          "music_brainz_release_id": track.metadata.musicBrainzReleaseId,
          "music_brainz_track_id": track.metadata.musicBrainzTrackId,
          "music_brainz_recording_id": track.metadata.musicBrainzRecordingId,
          "date_added": track.dateAdded.toUtc().toIso8601String(),
        },
      );

      await syncRepository.performSync();

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      final updatedTrack =
          decodeOnlineTrack(db, applicationSupportDirectory, response.data);

      final info = await playedTrackRepository.getTrackHistoryInfo(
        updatedTrack.id,
      );

      return updatedTrack.copyWith(
        historyInfo: () => info,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  int _activeUploads = 0;
  final List<Completer<void>> _waitingUploads = [];

  Future<Track> uploadAudio(
    File file, {
    StreamController<double>? progress,
  }) async {
    while (_activeUploads >= 4) {
      final completer = Completer<void>();
      _waitingUploads.add(completer);
      await completer.future;
    }

    _activeUploads++;

    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        "audio": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await AppApi().dio.post(
            "/track/upload",
            data: formData,
            onSendProgress: progress != null
                ? (int sent, int total) {
                    progress.add(sent / total);
                  }
                : null,
            options: Options(
              receiveTimeout: const Duration(hours: 3),
            ),
          );

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    } finally {
      _activeUploads--;

      if (_waitingUploads.isNotEmpty) {
        final next = _waitingUploads.removeAt(0);
        next.complete();
      }
    }
  }

  Future<Track> changeTrackAudio(int id, File file) async {
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      "audio": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      final response = await AppApi().dio.put(
            "/track/$id/audio",
            data: formData,
            options: Options(
              receiveTimeout: const Duration(hours: 3),
            ),
          );

      await syncRepository.performSync();

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Track> changeTrackCover(int id, File file) async {
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      final response = await AppApi().dio.put(
            "/track/$id/cover",
            data: formData,
          );

      await syncRepository.performSync();

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Track> deleteTrackById(int id) async {
    try {
      final response = await AppApi().dio.delete("/track/$id");

      await syncRepository.performSync();

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  importPendingTracks() async {
    try {
      await AppApi().dio.post("/track/import");

      await syncRepository.performSync();
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

  Future<Track> scanAudio(int id) async {
    try {
      final response = await AppApi().dio.get(
            "/track/$id/scan",
            options: Options(
              receiveTimeout: const Duration(seconds: 120),
            ),
          );

      await syncRepository.performSync();

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Track> advancedAudioScan(int id) async {
    try {
      final response = await AppApi().dio.get(
            "/track/$id/scan?advanced_scan=true",
            options: Options(
              receiveTimeout: const Duration(seconds: 120),
            ),
          );

      await syncRepository.performSync();

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Track> setTrackScore(int id, double score) async {
    try {
      final response = await AppApi().dio.put(
        "/track/$id/score",
        data: {
          "score": score,
        },
      );

      await syncRepository.performSync();

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Track> setTrackAlbums(
    int trackId,
    List<Album> albums,
  ) async {
    try {
      final response = await AppApi().dio.put(
        "/track/$trackId/albums",
        data: {
          "album_ids": albums.map((album) => album.id).toList(),
        },
      );

      await syncRepository.performSync();

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }

  Future<Track> setTrackArtists(
    int trackId,
    List<Artist> artists,
  ) async {
    try {
      final response = await AppApi().dio.put(
        "/track/$trackId/artists",
        data: {
          "artist_ids": artists.map((artist) => artist.id).toList(),
        },
      );

      print("E");
      await syncRepository.performSync();
      print("ABCD");

      final db = await DatabaseService.getDatabase();

      final applicationSupportDirectory =
          (await getMelodinkInstanceSupportDirectory()).path;

      return decodeOnlineTrack(
        db,
        applicationSupportDirectory,
        response.data,
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode == 404) {
        throw TrackNotFoundException();
      }

      throw ServerUnknownException();
    } catch (e) {
      mainLogger.e(e);
      throw ServerUnknownException();
    }
  }
}

final trackRepositoryProvider = Provider(
  (ref) => TrackRepository(
    playedTrackRepository: ref.watch(
      playedTrackRepositoryProvider,
    ),
    syncRepository: ref.watch(
      syncRepositoryProvider,
    ),
    networkInfo: ref.watch(
      networkInfoProvider,
    ),
  ),
);
