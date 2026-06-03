import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_score.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

Widget _sortIcon(TrackSortField field, TrackSort? currentSort) {
  if (currentSort?.field != field) return const SizedBox.shrink();
  final isDesc = currentSort?.direction == SortDirection.desc;
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Icon(isDesc ? Icons.arrow_downward : Icons.arrow_upward, size: 12),
  );
}

Widget _sortableBlock({
  required Widget child,
  required TrackSortField sortField,
  required TrackSort? currentSort,
  required void Function(TrackSortField)? onSort,
}) {
  if (onSort == null) return child;
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => onSort(sortField),
      behavior: HitTestBehavior.opaque,
      child: child,
    ),
  );
}

class DesktopTrackHeader extends StatelessWidget {
  final List<DesktopTrackModule> modules;
  final TrackSort? currentSort;
  final void Function(TrackSortField)? onSort;

  const DesktopTrackHeader({
    super.key,
    required this.modules,
    this.currentSort,
    this.onSort,
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
                    yield SizedBox(width: module.leftPadding);
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
                        child: _sortableBlock(
                          sortField: TrackSortField.title,
                          currentSort: currentSort,
                          onSort: onSort,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.general.trackTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 14 * 0.03,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              _sortIcon(TrackSortField.title, currentSort),
                            ],
                          ),
                        ),
                      );
                    case DesktopTrackModule.album:
                      yield Expanded(
                        child: _sortableBlock(
                          sortField: TrackSortField.album,
                          currentSort: currentSort,
                          onSort: onSort,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.general.album,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 14 * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _sortIcon(TrackSortField.album, currentSort),
                            ],
                          ),
                        ),
                      );
                    case DesktopTrackModule.lastPlayed:
                      yield SizedBox(
                        width: module.width,
                        child: _sortableBlock(
                          sortField: TrackSortField.lastPlayed,
                          currentSort: currentSort,
                          onSort: onSort,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.general.lastPlayed,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 14 * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _sortIcon(TrackSortField.lastPlayed, currentSort),
                            ],
                          ),
                        ),
                      );
                    case DesktopTrackModule.playedCount:
                      yield SizedBox(
                        width: module.width,
                        child: _sortableBlock(
                          sortField: TrackSortField.count,
                          currentSort: currentSort,
                          onSort: onSort,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.general.playedCount,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 14 * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _sortIcon(TrackSortField.count, currentSort),
                            ],
                          ),
                        ),
                      );
                    case DesktopTrackModule.dateAdded:
                      yield SizedBox(
                        width: module.width,
                        child: _sortableBlock(
                          sortField: TrackSortField.dateAdded,
                          currentSort: currentSort,
                          onSort: onSort,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.general.dateAdded,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 14 * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _sortIcon(TrackSortField.dateAdded, currentSort),
                            ],
                          ),
                        ),
                      );
                    case DesktopTrackModule.quality:
                      yield SizedBox(
                        width: module.width,
                        child: _sortableBlock(
                          sortField: TrackSortField.quality,
                          currentSort: currentSort,
                          onSort: onSort,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.general.quality,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 14 * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _sortIcon(TrackSortField.quality, currentSort),
                            ],
                          ),
                        ),
                      );
                    case DesktopTrackModule.score:
                      yield Builder(
                        builder: (context) {
                          final scoringSystem = context
                              .watch<SettingsViewModel>()
                              .currentScoringSystem();

                          return SizedBox(
                            width: TrackScore.getSize(scoringSystem),
                            child: _sortableBlock(
                              sortField: TrackSortField.score,
                              currentSort: currentSort,
                              onSort: onSort,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    t.general.score,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      letterSpacing: 14 * 0.03,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  _sortIcon(TrackSortField.score, currentSort),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    case DesktopTrackModule.duration:
                      yield SizedBox(
                        width: module.width,
                        child: _sortableBlock(
                          sortField: TrackSortField.duration,
                          currentSort: currentSort,
                          onSort: onSort,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.general.duration,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 14 * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _sortIcon(TrackSortField.duration, currentSort),
                            ],
                          ),
                        ),
                      );
                    case DesktopTrackModule.moreActions:
                      yield SizedBox(width: module.width);
                    case DesktopTrackModule.reorderable:
                      yield SizedBox(width: module.width);
                    case DesktopTrackModule.remove:
                      yield SizedBox(width: module.width);
                  }

                  if (module.rightPadding != 0) {
                    yield SizedBox(width: module.rightPadding);
                  }
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class StickyDesktopTrackHeader extends StatelessWidget {
  final List<DesktopTrackModule> modules;
  final ScrollController scrollController;
  final GlobalKey scrollViewKey;
  final TrackSort? currentSort;
  final void Function(TrackSortField)? onSort;

  const StickyDesktopTrackHeader({
    super.key,
    required this.modules,
    required this.scrollController,
    required this.scrollViewKey,
    this.currentSort,
    this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPinnedHeader(
      child: HookBuilder(
        builder: (context) {
          final isDocked = useState(true);

          final barKey = useMemoized(() => GlobalKey());

          void update() {
            final barRenderBox = barKey.currentContext?.findRenderObject();

            if (barRenderBox is! RenderBox) {
              return;
            }

            final scrollViewRenderBox = scrollViewKey.currentContext
                ?.findRenderObject();

            if (scrollViewRenderBox is! RenderBox) {
              return;
            }

            final position = barRenderBox.localToGlobal(
              Offset.zero,
              ancestor: scrollViewRenderBox,
            );

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

          return AppScreenTypeLayoutBuilder(
            builder: (context, size) {
              return Stack(
                children: [
                  if (size == AppScreenTypeLayout.desktop)
                    Opacity(
                      opacity: isDocked.value ? 0 : 1,
                      child: RepaintBoundary(
                        child: SizedBox(
                          height: 40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            child: GradientBackground(
                              widthMul: 5,
                              heightTopMul: 50,
                            ),
                          ),
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
                        top: Radius.circular(8),
                      ),
                    ),
                    child: size == AppScreenTypeLayout.desktop
                        ? DesktopTrackHeader(
                            modules: modules,
                            currentSort: currentSort,
                            onSort: onSort,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
