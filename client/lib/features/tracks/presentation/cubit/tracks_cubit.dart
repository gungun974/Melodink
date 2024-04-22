import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/usecases/usecase.dart';
import 'package:melodink_client/features/tracks/domain/usecases/get_all_tracks.dart';

import '../../domain/entities/track.dart';

abstract class TracksState extends Equatable {
  const TracksState();

  @override
  List<Object> get props => [];
}

class TracksInitial extends TracksState {}

class TracksLoading extends TracksState {
  final List<Track> tracks;

  const TracksLoading({required this.tracks});

  @override
  List<Object> get props => [tracks];
}

class TracksLoaded extends TracksState {
  final List<Track> tracks;

  const TracksLoaded({required this.tracks});

  @override
  List<Object> get props => [tracks];
}

class TracksCubit extends Cubit<TracksState> {
  final GetAllTracks getAllTracks;

  TracksCubit({
    required this.getAllTracks,
  }) : super(TracksInitial());

  void loadAllTracks() async {
    final result = await getAllTracks(NoParams());

    final tracks = result.match(
      (left) {
        return null;
      },
      (right) => right,
    );

    if (tracks == null) return;

    emit(TracksLoaded(tracks: tracks));
  }
}
