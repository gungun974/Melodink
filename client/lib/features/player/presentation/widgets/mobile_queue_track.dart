import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class MobileQueueTrack extends StatelessWidget {
  final MinimalTrack track;

  final void Function(MinimalTrack track) playCallback;

  const MobileQueueTrack({
    super.key,
    required this.track,
    required this.playCallback,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        playCallback(track);
      },
      child: SizedBox(
        height: 50,
        child: Container(
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            fontSize: 14,
                            letterSpacing: 14 * 0.03,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.albumArtist,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 14 * 0.03,
                            color: Colors.grey[350],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: ReorderableListener(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.only(left: 16),
                    color: Colors.transparent,
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: AdwaitaIcon(AdwaitaIcons.menu),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
