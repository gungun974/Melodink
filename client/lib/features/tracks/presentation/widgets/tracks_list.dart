import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/helpers/timeago.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TracksList extends StatelessWidget {
  final List<Track> tracks;

  const TracksList({
    super.key,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SliverToBoxAdapter(
        child: buildTableHeader(),
      ),
      SliverFixedExtentList(
        itemExtent: 56,
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return buildTableRow(context, tracks[index], index + 1);
          },
          childCount: tracks.length,
        ),
      )
    ]);
  }
}

Widget buildTableHeader() {
  return Container(
    color: const Color.fromRGBO(0, 0, 0, 0.08),
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        SizedBox(
            width: 32,
            child: Text(
              '#',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w500),
            )),
        SizedBox(width: 16),
        Expanded(
            flex: 6,
            child: Text(
              'Title',
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.w500),
            )),
        SizedBox(width: 16),
        Expanded(
            flex: 4,
            child: Text(
              'Album',
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.w500),
            )),
        SizedBox(width: 16),
        Expanded(
            flex: 3,
            child: Text(
              'Date added',
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.w500),
            )),
        SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AdwaitaIcon(
            AdwaitaIcons.clock,
            size: 18,
          ),
        ),
        SizedBox(width: 16),
      ],
    ),
  );
}

Widget buildTableRow(BuildContext context, Track track, int index) {
  return GestureDetector(
    onTap: () {
      BlocProvider.of<PlayerCubit>(context).loadTrack(track);
    },
    child: Container(
      color: const Color.fromRGBO(0, 0, 0, 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
              width: 32,
              child: Text(index.toString(), textAlign: TextAlign.right)),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                FadeInImage(
                  height: 40,
                  placeholder: const AssetImage(
                    "assets/melodink_track_cover_not_found.png",
                  ),
                  image: NetworkImage("$appUrl/api/track/${track.id}/image"),
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      "assets/melodink_track_cover_not_found.png",
                      width: 40,
                      height: 40,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: track.title,
                        waitDuration: const Duration(milliseconds: 800),
                        child: Text(
                          track.title,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        track.metadata.artist,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
              flex: 4,
              child: Text(track.metadata.artist, textAlign: TextAlign.left)),
          const SizedBox(width: 16),
          Expanded(
              flex: 3,
              child: Text(
                  formatTimeago(
                    track.dateAdded,
                  ),
                  textAlign: TextAlign.left)),
          const SizedBox(width: 16),
          Expanded(
              flex: 1,
              child: Text(
                  durationToTime(
                    track.duration,
                  ),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 16),
        ],
      ),
    ),
  );
}
