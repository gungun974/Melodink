import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';

abstract class TrackShuffler {
  List<IndexedTrack> shuffle(List<IndexedTrack> tracks);
}

class NormalTrackShuffler implements TrackShuffler {
  @override
  List<IndexedTrack> shuffle(List<IndexedTrack> rawTracks) {
    final tracks = [...rawTracks];

    tracks.shuffle();

    return tracks;
  }
}
