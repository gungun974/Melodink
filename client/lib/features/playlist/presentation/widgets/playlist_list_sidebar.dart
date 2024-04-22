import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/features/playlist/presentation/cubit/playlist_manager_cubit.dart';
import 'package:melodink_client/injection_container.dart';

class PlaylistListSidebar extends StatefulWidget {
  const PlaylistListSidebar({
    super.key,
  });

  @override
  State<PlaylistListSidebar> createState() => _PlaylistListSidebarState();
}

class _PlaylistListSidebarState extends State<PlaylistListSidebar> {
  final PlaylistManagerCubit cubit = sl();

  @override
  void initState() {
    super.initState();
    cubit.loadAllPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.08),
      width: 72 * 3,
      child: BlocBuilder<PlaylistManagerCubit, PlaylistManagerState>(
          bloc: cubit,
          builder: (BuildContext context, PlaylistManagerState state) {
            if (state is PlaylistManagerLoaded) {
              return ListView.builder(
                itemCount: state.albums.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(state.albums[index].name),
                  );
                },
              );
            }

            return Container();
          }),
    );
  }
}
