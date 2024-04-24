import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';

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
  final TrackRepository trackRepository;

  TracksCubit({
    required this.trackRepository,
  }) : super(TracksInitial());

  void loadAllTracks() async {
    final result = await trackRepository.getAllTracks();

    if (result case Ok(ok: final tracks)) {
      emit(TracksLoaded(tracks: tracks));
    }
  }
}
