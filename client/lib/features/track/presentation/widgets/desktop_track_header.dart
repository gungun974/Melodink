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
          child: DesktopTrackModuleLayout(
              modules: modules,
              builder: (context, newModules) {
                return Row(
                  children: newModules.expand((module) sync* {
                    if (module.leftPadding != 0) {
                      yield SizedBox(
                        width: module.leftPadding,
                      );
                    }

                    switch (module) {
                      case DesktopTrackModule.title:
                        yield const SizedBox(
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
                        );
                        yield const SizedBox(width: 24);
                        yield const Expanded(
                          child: Text(
                            "Title",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      case DesktopTrackModule.album:
                        yield const Expanded(
                          child: Text(
                            "Album",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.lastPlayed:
                        yield SizedBox(
                          width: module.width,
                          child: const Text(
                            "Last Played",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.playedCount:
                        yield SizedBox(
                          width: module.width,
                          child: const Text(
                            "Count",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.dateAdded:
                        yield SizedBox(
                          width: module.width,
                          child: const Text(
                            "Date added",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.quality:
                        yield SizedBox(
                          width: module.width,
                          child: const Text(
                            "Quality",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.duration:
                        yield SizedBox(
                          width: module.width,
                          child: const Text(
                            "Duration",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.moreActions:
                        yield SizedBox(width: module.width);
                      case DesktopTrackModule.reorderable:
                        yield SizedBox(width: module.width);
                    }

                    if (module.rightPadding != 0) {
                      yield SizedBox(
                        width: module.rightPadding,
                      );
                    }
                  }).toList(),
                );
              }),
        ),
      ),
    );
  }
}
