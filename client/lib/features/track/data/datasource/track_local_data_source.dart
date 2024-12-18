import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/library/data/datasource/album_local_data_source.dart';
import 'package:melodink_client/features/library/data/datasource/playlist_local_data_source.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';

class TrackLocalDataSource {
  final AlbumLocalDataSource albumLocalDataSource;

  final PlaylistLocalDataSource playlistLocalDataSource;

  TrackLocalDataSource({
    required this.albumLocalDataSource,
    required this.playlistLocalDataSource,
  });

  Future<List<MinimalTrack>> getAllTracks() async {
    final List<MinimalTrack> tracks = [];

    final allAlbums = await albumLocalDataSource.getAllAlbums();

    for (final album in allAlbums) {
      if (!album.downloadTracks) {
        continue;
      }
      for (final track in album.tracks) {
        if (tracks.indexWhere((atrack) => atrack.id == track.id) == -1) {
          tracks.add(track);
        }
      }
    }

    final allPlaylists = await playlistLocalDataSource.getAllPlaylists();

    for (final playlist in allPlaylists) {
      for (final track in playlist.tracks) {
        if (tracks.indexWhere((atrack) => atrack.id == track.id) == -1) {
          tracks.add(track);
        }
      }
    }

    return tracks;
  }
}

final trackLocalDataSourceProvider = Provider(
  (ref) => TrackLocalDataSource(
    albumLocalDataSource: ref.watch(
      albumLocalDataSourceProvider,
    ),
    playlistLocalDataSource: ref.watch(
      playlistLocalDataSourceProvider,
    ),
  ),
);
