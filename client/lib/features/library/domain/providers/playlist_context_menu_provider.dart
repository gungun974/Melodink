import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_provider.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/providers/download_manager_provider.dart';
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
    _playlistRepository = ref.watch(playlistRepositoryProvider);

    return await _playlistRepository.getAllPlaylists();
  }

  addTracks(Playlist playlist, List<Track> tracks) async {
    await _playlistRepository.addPlaylistTracks(playlist.id, tracks);

    final _ = ref.refresh(playlistByIdProvider(playlist.id));
  }

  setTracks(Playlist playlist, List<Track> tracks) async {
    await _playlistRepository.setPlaylistTracks(
      playlist.id,
      tracks,
    );

    await ref
        .read(downloadManagerNotifierProvider.notifier)
        .deleteOrphanTracks();

    final _ = ref.refresh(playlistByIdProvider(playlist.id));
  }
}
