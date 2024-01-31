import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/features/tracks/presentation/cubit/tracks_cubit.dart';
import 'package:melodink_client/features/tracks/presentation/widgets/tracks_info_header.dart';
import 'package:melodink_client/features/tracks/presentation/widgets/tracks_list.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TracksPage extends StatefulWidget {
  const TracksPage({
    super.key,
  });

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
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

        List<Track> tracks = [];

        if (state is TracksLoading) {
          tracks = state.tracks;
        }

        if (state is TracksLoaded) {
          tracks = state.tracks;
        }

        return CustomScrollView(
          slivers: [
            SliverContainer(
              maxWidth: 1200,
              padding: 32,
              sliver: SliverPadding(
                padding: const EdgeInsets.only(top: 48),
                sliver: SliverToBoxAdapter(
                  child: TracksInfoHeader(tracks: tracks),
                ),
              ),
            ),
            SliverContainer(
              maxWidth: 1200,
              padding: 32,
              sliver: SliverPadding(
                padding: const EdgeInsets.only(top: 32, bottom: 48),
                sliver: TracksList(tracks: tracks),
              ),
            ),
          ],
        );
      },
    );
  }
}
