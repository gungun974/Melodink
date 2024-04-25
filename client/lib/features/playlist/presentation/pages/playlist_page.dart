import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/features/playlist/presentation/widgets/playlist_info_header.dart';
import 'package:melodink_client/features/tracks/presentation/widgets/tracks_list.dart';
import 'package:responsive_builder/responsive_builder.dart';

class PlaylistPage extends StatelessWidget {
  final Playlist playlist;

  const PlaylistPage({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    void playTrack(int index, List<Track> tracks) {
      BlocProvider.of<PlayerCubit>(context).loadTracksPlaylist(tracks, index);
    }

    return ResponsiveBuilder(
      builder: (
        context,
        sizingInformation,
      ) {
        if (sizingInformation.deviceScreenType != DeviceScreenType.desktop) {
          return CustomScrollView(
            slivers: [
              SliverContainer(
                maxWidth: 1200,
                padding: 0,
                sliver: SliverPadding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  sliver: TracksList(
                    tracks: playlist.tracks,
                    playCallback: playTrack,
                  ),
                ),
              ),
            ],
          );
        }

        return CustomScrollView(
          slivers: [
            SliverContainer(
              maxWidth: 1200,
              padding: 32,
              sliver: SliverPadding(
                padding: const EdgeInsets.only(top: 32),
                sliver: SliverToBoxAdapter(
                  child: TracksInfoHeader(playlist: playlist),
                ),
              ),
            ),
            SliverContainer(
              maxWidth: 1200,
              padding: 32,
              sliver: SliverPadding(
                padding: const EdgeInsets.only(top: 32, bottom: 48),
                sliver: TracksList(
                  tracks: playlist.tracks,
                  playCallback: playTrack,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
