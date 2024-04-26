import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/features/playlist/presentation/cubit/album_page_cubit.dart';
import 'package:melodink_client/features/playlist/presentation/pages/playlist_page.dart';
import 'package:melodink_client/injection_container.dart';

class AlbumPage extends StatefulWidget {
  final String id;

  const AlbumPage({
    super.key,
    required this.id,
  });

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  AlbumPageCubit cubit = sl();

  @override
  void initState() {
    super.initState();
    cubit.loadAlbum(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlbumPageCubit, AlbumPageState>(
      bloc: cubit,
      builder: (BuildContext context, AlbumPageState state) {
        if (state is! AlbumPageLoaded) {
          return Container();
        }

        return PlaylistPage(
          playlist: state.album,
        );
      },
    );
  }
}
