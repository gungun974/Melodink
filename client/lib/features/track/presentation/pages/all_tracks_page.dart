import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:melodink_client/features/playlist/presentation/pages/playlist_page.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/presentation/cubit/tracks_cubit.dart';
import 'package:melodink_client/injection_container.dart';

class AllTracksPage extends StatefulWidget {
  const AllTracksPage({
    super.key,
  });

  @override
  State<AllTracksPage> createState() => _AllTracksPageState();
}

class _AllTracksPageState extends State<AllTracksPage> {
  final TracksCubit cubit = sl();

  @override
  void initState() {
    super.initState();
    cubit.loadAllTracks();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TracksCubit, TracksState>(
      bloc: cubit,
      builder: (BuildContext context, TracksState state) {
        if (state is TracksInitial) {
          return Container();
        }

        List<MinimalTrack> tracks = [];

        if (state is TracksLoading) {
          tracks = state.tracks;
        }

        if (state is TracksLoaded) {
          tracks = state.tracks;
        }

        return PlaylistPage(
          playlist: Playlist(
            id: "",
            name: "All tracks",
            description: "All tracks",
            albumArtist: "",
            type: PlaylistType.allTracks,
            tracks: tracks,
          ),
        );
      },
    );
  }
}
