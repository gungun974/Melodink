import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/helpers/timeago.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TracksList extends StatelessWidget {
  final List<Track> tracks;

  final bool withHeader;

  final int numberOffset;

  final void Function(int index, List<Track> tracks) playCallback;

  const TracksList({
    super.key,
    required this.tracks,
    required this.playCallback,
    this.withHeader = true,
    this.numberOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SliverToBoxAdapter(
        child: ResponsiveBuilder(builder: (context, sizingInformation) {
          if (sizingInformation.deviceScreenType != DeviceScreenType.desktop ||
              !withHeader) {
            return Container(
              color: const Color.fromRGBO(0, 0, 0, 0.08),
              height: 6,
            );
          }
          return buildTableHeader();
        }),
      ),
      SliverFixedExtentList(
        itemExtent: 56,
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ResponsiveBuilder(
              builder: (context, sizingInformation) {
                return buildTableRow(
                  context,
                  tracks[index],
                  index + 1 + numberOffset,
                  () {
                    playCallback(index, tracks);
                  },
                  minimal: sizingInformation.deviceScreenType !=
                      DeviceScreenType.desktop,
                );
              },
            );
          },
          childCount: tracks.length,
        ),
      ),
      SliverToBoxAdapter(
        child: Container(
          color: const Color.fromRGBO(0, 0, 0, 0.08),
          height: 6,
        ),
      ),
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

Widget buildTableRow(
  BuildContext context,
  Track track,
  int displayNumber,
  VoidCallback playCallback, {
  bool minimal = false,
}) {
  return GestureDetector(
    key: Key("trackRow[$displayNumber]"),
    onTap: playCallback,
    onSecondaryTap: () {
      BlocProvider.of<PlayerCubit>(context).addTrackToQueue(track);
    },
    child: Container(
      color: const Color.fromRGBO(0, 0, 0, 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (!minimal)
            SizedBox(
              width: 32,
              child: Text(
                key: const Key("numberText"),
                displayNumber.toString(),
                textAlign: TextAlign.right,
              ),
            ),
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
                  image: track.cacheFile?.getImageProvider() ??
                      NetworkImage("$appUrl/api/track/${track.id}/image"),
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
                          key: const Key("titleText"),
                          track.title,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: track.metadata.artist,
                        waitDuration: const Duration(milliseconds: 800),
                        child: Text(
                          key: const Key("artistText"),
                          track.metadata.artist,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!minimal) ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Tooltip(
                message: track.album,
                waitDuration: const Duration(milliseconds: 800),
                child: Text(
                  key: const Key("albumText"),
                  track.album,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                key: const Key("dateAddedText"),
                formatTimeago(
                  track.dateAdded,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Text(
                key: const Key("durationText"),
                durationToTime(
                  track.duration,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
    ),
  );
}
