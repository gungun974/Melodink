import 'package:flutter/material.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

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
                        yield Expanded(
                          child: Text(
                            t.general.trackTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      case DesktopTrackModule.album:
                        yield Expanded(
                          child: Text(
                            t.general.album,
                            style: const TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.lastPlayed:
                        yield SizedBox(
                          width: module.width,
                          child: Text(
                            t.general.lastPlayed,
                            style: const TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.playedCount:
                        yield SizedBox(
                          width: module.width,
                          child: Text(
                            t.general.playedCount,
                            style: const TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.dateAdded:
                        yield SizedBox(
                          width: module.width,
                          child: Text(
                            t.general.dateAdded,
                            style: const TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.quality:
                        yield SizedBox(
                          width: module.width,
                          child: Text(
                            t.general.quality,
                            style: const TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DesktopTrackModule.duration:
                        yield SizedBox(
                          width: module.width,
                          child: Text(
                            t.general.duration,
                            style: const TextStyle(
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
