import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';

class CurrentTrackInfo extends StatelessWidget {
  const CurrentTrackInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        if (state is! PlayerPlaying) {
          return Container();
        }
        return Row(
          children: [
            FadeInImage(
              height: 40,
              placeholder: const AssetImage(
                "assets/melodink_track_cover_not_found.png",
              ),
              image: NetworkImage(
                  "$appUrl/api/track/${state.currentTrack.id}/image"),
              imageErrorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  "assets/melodink_track_cover_not_found.png",
                  width: 40,
                  height: 40,
                );
              },
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.currentTrack.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.currentTrack.metadata.artist,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
