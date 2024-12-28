import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_score.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:sliver_tools/sliver_tools.dart';

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
                      case DesktopTrackModule.score:
                        yield Consumer(builder: (context, ref, _) {
                          final scoringSystem = ref.watch(
                            currentScoringSystemProvider,
                          );

                          return SizedBox(
                            width: TrackScore.getSize(scoringSystem),
                            child: Text(
                              t.general.score,
                              style: const TextStyle(
                                fontSize: 14,
                                letterSpacing: 14 * 0.03,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        });
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

class StickyDesktopTrackHeader extends StatelessWidget {
  final List<DesktopTrackModule> modules;
  final ScrollController scrollController;
  final GlobalKey scrollViewKey;

  const StickyDesktopTrackHeader({
    super.key,
    required this.modules,
    required this.scrollController,
    required this.scrollViewKey,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPinnedHeader(
      child: HookBuilder(builder: (context) {
        final isDocked = useState(true);

        final barKey = useMemoized(() => GlobalKey());

        void update() {
          final barRenderBox = barKey.currentContext?.findRenderObject();

          if (barRenderBox is! RenderBox) {
            return;
          }

          final scrollViewRenderBox =
              scrollViewKey.currentContext?.findRenderObject();

          if (scrollViewRenderBox is! RenderBox) {
            return;
          }

          final position = barRenderBox.localToGlobal(Offset.zero,
              ancestor: scrollViewRenderBox);

          isDocked.value = (position).dy > 0 || scrollController.offset < 1;
        }

        void onScroll() {
          update();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            update();
          });
        }

        useEffect(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              onScroll();
            }
          });

          scrollController.addListener(onScroll);

          return () {
            scrollController.removeListener(onScroll);
          };
        }, [scrollController]);

        return AppScreenTypeLayoutBuilder(builder: (context, size) {
          return Stack(
            children: [
              if (size == AppScreenTypeLayout.desktop)
                Opacity(
                  opacity: isDocked.value ? 0 : 1,
                  child: RepaintBoundary(
                    child: SizedBox(
                      height: 40,
                      child: LayoutBuilder(builder: (context, layout) {
                        return ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                              8,
                            ),
                          ),
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            maxWidth: layout.maxWidth * 5,
                            maxHeight: layout.maxHeight * 50,
                            child: GradientBackground(),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              Container(
                key: barKey,
                decoration: BoxDecoration(
                  color: isDocked.value
                      ? Color.fromRGBO(0, 0, 0, 0.03)
                      : Colors.transparent,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      8,
                    ),
                  ),
                ),
                child: size == AppScreenTypeLayout.desktop
                    ? DesktopTrackHeader(
                        modules: modules,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        });
      }),
    );
  }
}
