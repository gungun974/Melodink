import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';

part 'playlist.freezed.dart';

enum PlaylistType {
  album,
  artist,
  custom,
  allTracks,
}

@freezed
class Playlist with _$Playlist {
  const factory Playlist({
    required String id,
    required String name,
    required String description,
    required String albumArtist,
    required PlaylistType type,
    required List<Track> tracks,
  }) = _Playlist;
}
