import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/playlist/presentation/cubit/playlist_manager_cubit.dart';
import 'package:melodink_client/features/playlist/presentation/widgets/playlist_collections_grid.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:responsive_builder/responsive_builder.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final PlaylistManagerCubit cubit = sl();

  @override
  void initState() {
    super.initState();
    cubit.loadAllPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistManagerCubit, PlaylistManagerState>(
      bloc: cubit,
      builder: (BuildContext context, PlaylistManagerState state) {
        if (state is! PlaylistManagerLoaded) {
          return Container();
        }

        return ResponsiveBuilder(builder: (
          context,
          sizingInformation,
        ) {
          final padding =
              sizingInformation.deviceScreenType != DeviceScreenType.desktop
                  ? 16.0
                  : 32.0;

          return CustomScrollView(
            slivers: [
              SliverContainer(
                maxWidth: 1200,
                padding: padding,
                sliver: SliverPadding(
                  padding: EdgeInsets.only(
                      top: sizingInformation.deviceScreenType !=
                              DeviceScreenType.desktop
                          ? 24.0
                          : 32.0),
                  sliver: const SliverToBoxAdapter(
                    child: Text(
                      "Library",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 40,
                      ),
                    ),
                  ),
                ),
              ),
              SliverContainer(
                maxWidth: 1200,
                padding: padding,
                sliver: SliverPadding(
                  padding: EdgeInsets.only(
                      top: sizingInformation.deviceScreenType !=
                              DeviceScreenType.desktop
                          ? 8.0
                          : 32.0,
                      bottom: sizingInformation.deviceScreenType !=
                              DeviceScreenType.desktop
                          ? 8.0
                          : 32.0),
                  sliver: PlaylistCollectionsGrid(
                    title: "Albums",
                    playlists: state.albums,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
