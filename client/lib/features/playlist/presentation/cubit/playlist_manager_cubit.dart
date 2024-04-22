import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:melodink_client/features/playlist/domain/repositories/playlist_repository.dart';

class PlaylistManagerState extends Equatable {
  const PlaylistManagerState();

  @override
  List<Object> get props => [];
}

class PlaylistManagerInitial extends PlaylistManagerState {}

class PlaylistManagerLoading extends PlaylistManagerState {}

class PlaylistManagerLoaded extends PlaylistManagerState {
  final List<Playlist> albums;

  const PlaylistManagerLoaded({required this.albums});

  @override
  List<Object> get props => [albums];
}

class PlaylistManagerCubit extends Cubit<PlaylistManagerState> {
  final PlaylistRepository playerRepository;

  PlaylistManagerCubit({
    required this.playerRepository,
  }) : super(PlaylistManagerInitial());

  void loadAllPlaylists() async {
    emit(PlaylistManagerLoading());

    final result = await playerRepository.getAllAlbums();

    final albums = result.match(
      (left) {
        return null;
      },
      (right) => right,
    );

    if (albums == null) return;

    emit(PlaylistManagerLoaded(albums: albums));
  }
}
