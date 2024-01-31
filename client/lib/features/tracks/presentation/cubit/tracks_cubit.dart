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
    final List<Track> tracks = [];

    final result = await getAllTracks(NoParams());

    final stream = result.match(
      (left) {
        return null;
      },
      (right) => right,
    );

    if (stream == null) return;

    await for (final track in stream) {
      tracks.add(track);

      emit(TracksLoading(tracks: [...tracks]));

      await Future.delayed(const Duration(milliseconds: 0));
    }

    emit(TracksLoaded(tracks: tracks));
  }
}
