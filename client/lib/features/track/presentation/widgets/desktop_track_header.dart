import 'package:flutter/material.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';

class DesktopTrackHeader extends StatelessWidget {
  final List<DesktopTrackModule> modules;

  const DesktopTrackHeader({
    super.key,
    required this.modules,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Center(
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: modules
                .map<List<Widget>>((module) {
                  return switch (module) {
                    DesktopTrackModule.title => [
                        const SizedBox(
                          width: 28,
                          child: Text(
                            "#",
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Title",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    DesktopTrackModule.album => [
                        const Expanded(
                          child: Text(
                            "Album",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    DesktopTrackModule.lastPlayed => [
                        const SizedBox(
                          width: 96,
                          child: Text(
                            "Last Played",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      ],
                    DesktopTrackModule.playedCount => [
                        const SizedBox(
                          width: 40,
                          child: Text(
                            "Count",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    DesktopTrackModule.dateAdded => [
                        const SizedBox(
                          width: 96,
                          child: Text(
                            "Date added",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    DesktopTrackModule.quality => [
                        const SizedBox(
                          width: 128,
                          child: Text(
                            "Quality",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    DesktopTrackModule.duration => [
                        const SizedBox(
                          width: 60,
                          child: Text(
                            "Duration",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    DesktopTrackModule.moreActions => [
                        const SizedBox(width: 72),
                      ],
                    DesktopTrackModule.reorderable => [
                        const SizedBox(width: 72),
                      ],
                  };
                })
                .expand((i) => i)
                .expand((element) sync* {
                  yield element;
                  yield const SizedBox(width: 8);
                })
                .toList(),
          ),
        ),
      ),
    );
  }
}
