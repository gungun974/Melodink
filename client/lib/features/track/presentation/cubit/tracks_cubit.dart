import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

abstract class TracksState extends Equatable {
  const TracksState();

  @override
  List<Object> get props => [];
}

class TracksInitial extends TracksState {}

class TracksLoading extends TracksState {
  final List<MinimalTrack> tracks;

  const TracksLoading({required this.tracks});

  @override
  List<Object> get props => [tracks];
}

class TracksLoaded extends TracksState {
  final List<MinimalTrack> tracks;

  const TracksLoaded({required this.tracks});

  @override
  List<Object> get props => [tracks];
}

class TracksCubit extends Cubit<TracksState> {
  TracksCubit() : super(TracksInitial());

  void loadAllTracks() async {
    emit(TracksLoaded(tracks: [
      MinimalTrack(
        id: 18,
        title: "Track 1",
        duration: const Duration(minutes: 4, seconds: 5),
        album: "test",
        trackNumber: 1,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 19,
        title: "Track 2",
        duration: const Duration(minutes: 4, seconds: 3),
        album: "test",
        trackNumber: 2,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 20,
        title: "Track 3",
        duration: const Duration(minutes: 4, seconds: 20),
        album: "test",
        trackNumber: 3,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 21,
        title: "Track 4",
        duration: const Duration(minutes: 4, seconds: 26),
        album: "test",
        trackNumber: 4,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 22,
        title: "Track 5",
        duration: const Duration(minutes: 4, seconds: 1),
        album: "test",
        trackNumber: 5,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 23,
        title: "Track 6",
        duration: const Duration(minutes: 4, seconds: 2),
        album: "test",
        trackNumber: 6,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 24,
        title: "Track 7",
        duration: const Duration(minutes: 5, seconds: 14),
        album: "test",
        trackNumber: 7,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 25,
        title: "Track 8",
        duration: const Duration(minutes: 4, seconds: 0),
        album: "test",
        trackNumber: 8,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 26,
        title: "Track 9",
        duration: const Duration(minutes: 4, seconds: 0),
        album: "test",
        trackNumber: 9,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 27,
        title: "Track 10",
        duration: const Duration(minutes: 3, seconds: 51),
        album: "test",
        trackNumber: 10,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 28,
        title: "Track 11",
        duration: const Duration(minutes: 4, seconds: 51),
        album: "test",
        trackNumber: 11,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 29,
        title: "Track 12",
        duration: const Duration(minutes: 4, seconds: 32),
        album: "test",
        trackNumber: 12,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 30,
        title: "Track 13",
        duration: const Duration(minutes: 5, seconds: 23),
        album: "test",
        trackNumber: 13,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
      MinimalTrack(
        id: 31,
        title: "Track 14",
        duration: const Duration(minutes: 5, seconds: 17),
        album: "test",
        trackNumber: 14,
        discNumber: 1,
        date: "2023",
        year: 2023,
        genre: "pop",
        artist: "y",
        albumArtist: "y",
        composer: "y",
        dateAdded: DateTime.now(),
      ),
    ]));
  }
}
