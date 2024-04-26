import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:melodink_client/features/playlist/domain/repositories/playlist_repository.dart';

class AlbumPageState extends Equatable {
  const AlbumPageState();

  @override
  List<Object> get props => [];
}

class AlbumPageInitial extends AlbumPageState {}

class AlbumPageLoading extends AlbumPageState {}

class AlbumPageNotFound extends AlbumPageState {}

class AlbumPageLoaded extends AlbumPageState {
  final Playlist album;

  const AlbumPageLoaded({required this.album});

  @override
  List<Object> get props => [album];
}

class AlbumPageCubit extends Cubit<AlbumPageState> {
  final PlaylistRepository playlistRepository;

  AlbumPageCubit({
    required this.playlistRepository,
  }) : super(AlbumPageInitial());

  void loadAlbum(String id) async {
    emit(AlbumPageLoading());

    final result = await playlistRepository.getAlbumById(id);

    switch (result) {
      case Ok(ok: final album):
        emit(AlbumPageLoaded(album: album));
      case Err(:final err):
        if (err is PlaylistNotFoundFailure) {
          emit(AlbumPageNotFound());
        }
    }
  }
}
