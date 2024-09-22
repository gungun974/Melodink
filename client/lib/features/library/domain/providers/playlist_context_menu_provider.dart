import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'playlist_context_menu_provider.g.dart';

class PlaylistContextMenuError extends Equatable {
  final String? title;
  final String message;

  const PlaylistContextMenuError({
    this.title,
    required this.message,
  });

  @override
  List<Object?> get props => [title, message];
}

@riverpod
class PlaylistContextMenuNotifier extends _$PlaylistContextMenuNotifier {
  late PlaylistRepository _playlistRepository;

  @override
  Future<List<Playlist>> build() async {
    _playlistRepository = ref.read(playlistRepositoryProvider);

    return await _playlistRepository.getAllPlaylists();
  }

  addTracks(Playlist playlist, List<MinimalTrack> tracks) async {
    await _playlistRepository.addPlaylistTracks(playlist.id, tracks);
  }
}
