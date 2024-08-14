import 'package:flutter/material.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/playlist/domain/entities/playlist.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/playlist/presentation/widgets/playlist_info_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/tracks_list.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:responsive_builder/responsive_builder.dart';

class PlaylistPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistPage({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final AudioController audioController = sl();

  @override
  Widget build(BuildContext context) {
    void playTrack(int index, List<MinimalTrack> tracks) {
      audioController.loadTracks(tracks, startAt: index);
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
                    tracks: widget.playlist.tracks,
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
                  child: TracksInfoHeader(playlist: widget.playlist),
                ),
              ),
            ),
            SliverContainer(
              maxWidth: 1200,
              padding: 32,
              sliver: SliverPadding(
                padding: const EdgeInsets.only(top: 32, bottom: 48),
                sliver: TracksList(
                  tracks: widget.playlist.tracks,
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
