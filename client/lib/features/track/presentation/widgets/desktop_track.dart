import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/helpers/is_touch_device.dart';
import 'package:melodink_client/core/helpers/timeago.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/context_menu_button.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/album_link_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_context_menu.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_score.dart';

enum DesktopTrackModule {
  title(width: 28 + 24, rightPadding: 24),
  album(width: 0, rightPadding: 4),
  lastPlayed(leftPadding: 4, width: 112, rightPadding: 4),
  playedCount(leftPadding: 4, width: 48, rightPadding: 8 + 4),
  dateAdded(leftPadding: 4, width: 96, rightPadding: 4),
  quality(leftPadding: 4, width: 128, rightPadding: 4),
  duration(leftPadding: 4, width: 60, rightPadding: 8),
  score(leftPadding: 0, width: 0, rightPadding: 0),
  moreActions(leftPadding: 0, width: 72, rightPadding: 4),
  reorderable(leftPadding: 4, width: 72, rightPadding: 4);

  final double width;
  final double leftPadding;
  final double rightPadding;

  const DesktopTrackModule({
    required this.width,
    this.leftPadding = 0,
    this.rightPadding = 0,
  });
}

class DesktopTrackModuleLayout extends ConsumerWidget {
  final List<DesktopTrackModule> modules;

  final Widget Function(
    BuildContext context,
    List<DesktopTrackModule> newModules,
  ) builder;

  const DesktopTrackModuleLayout({
    super.key,
    required this.modules,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoringSystem = ref.watch(currentScoringSystemProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final newModules = modules.toList();

      if (scoringSystem == AppSettingScoringSystem.none) {
        newModules.remove(DesktopTrackModule.score);
      }

      double calculateRemainingSpace() {
        double totalWidth = 0;
        int flex = 0;

        for (final module in newModules) {
          totalWidth += module.width + module.leftPadding + module.rightPadding;

          if (module == DesktopTrackModule.title ||
              module == DesktopTrackModule.album) {
            flex += 1;
          }

          if (module == DesktopTrackModule.score) {
            totalWidth += TrackScore.getSize(scoringSystem);
          }
        }

        final remainingSpace = constraints.maxWidth - totalWidth;

        if (flex == 0) {
          return remainingSpace;
        }

        return remainingSpace / flex;
      }

      const minimumRequiredSpace = 180;

      for (final removableModule in [
        DesktopTrackModule.quality,
        DesktopTrackModule.dateAdded,
        DesktopTrackModule.lastPlayed,
      ]) {
        if (calculateRemainingSpace() >= minimumRequiredSpace) {
          break;
        }

        newModules.remove(removableModule);
      }

      return builder(context, newModules);
    });
  }
}

class DesktopTrack extends HookConsumerWidget {
  final MinimalTrack track;

  final int trackNumber;
  final bool showImage;

  final List<DesktopTrackModule> modules;

  final void Function(MinimalTrack track) playCallback;

  final void Function(MinimalTrack track)? selectCallback;

  final bool selected;

  final List<MinimalTrack> selectedTracks;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    MinimalTrack track,
  )? singleCustomActionsBuilder;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    List<MinimalTrack> tracks,
  )? multiCustomActionsBuilder;

  const DesktopTrack({
    super.key,
    required this.track,
    required this.trackNumber,
    required this.playCallback,
    required this.modules,
    this.showImage = true,
    this.selectCallback,
    this.selected = false,
    this.selectedTracks = const [],
    this.singleCustomActionsBuilder,
    this.multiCustomActionsBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isServerReachable = ref.watch(isServerReachableProvider);

    final isCurrentTrack = ref.watch(isCurrentTrackProvider(track.id));

    final downloadedTrack = ref
        .watch(
          isTrackDownloadedProvider(track.id),
        )
        .valueOrNull;

    final trackContextMenuController = useMemoized(() => MenuController());

    final tracksContextMenuController = useMemoized(() => MenuController());

    final trackContextMenuKey = useMemoized(() => GlobalKey());

    final isHovering = useState(false);

    final trackWidget = MouseRegion(
      onEnter: (_) {
        isHovering.value = true;
      },
      onExit: (_) {
        isHovering.value = false;
      },
      child: Listener(
        onPointerDown: isTouchDevice(context)
            ? null
            : (details) {
                final callback = selectCallback;

                if (selectedTracks.isNotEmpty &&
                    details.buttons == kSecondaryButton) {
                  return;
                }

                if (callback != null) {
                  callback(track);
                }
              },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: !isTouchDevice(context)
              ? null
              : () {
                  playCallback(track);
                },
          onDoubleTap: isTouchDevice(context)
              ? null
              : () {
                  playCallback(track);
                },
          child: TrackContextMenu(
            key: trackContextMenuKey,
            track: track,
            tracks: selectedTracks,
            singleMenuController: trackContextMenuController,
            multiMenuController: tracksContextMenuController,
            singleCustomActionsBuilder: singleCustomActionsBuilder,
            multiCustomActionsBuilder: multiCustomActionsBuilder,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: selected
                    ? const Color.fromRGBO(0, 0, 0, 0.075)
                    : (isHovering.value
                        ? const Color.fromRGBO(0, 0, 0, 0.05)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
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
                          yield SizedBox(
                            width: 28,
                            child: Text(
                              "$trackNumber",
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 14,
                                letterSpacing: 14 * 0.03,
                                fontWeight: FontWeight.w500,
                                color: isCurrentTrack
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          );
                          yield const SizedBox(width: 24);
                          yield Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (showImage)
                                    AuthCachedNetworkImage(
                                      imageUrl: downloadedTrack
                                              ?.getCoverUrl() ??
                                          track.getCompressedCoverUrl(
                                            TrackCompressedCoverQuality.small,
                                          ),
                                      placeholder: (context, url) =>
                                          Image.asset(
                                        "assets/melodink_track_cover_not_found.png",
                                      ),
                                      errorWidget: (context, url, error) {
                                        return Image.asset(
                                          "assets/melodink_track_cover_not_found.png",
                                        );
                                      },
                                    ),
                                  if (showImage) const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Tooltip(
                                          message: track.title,
                                          waitDuration:
                                              const Duration(milliseconds: 800),
                                          child: Text(
                                            track.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              letterSpacing: 14 * 0.03,
                                              fontWeight: FontWeight.w500,
                                              color: isCurrentTrack
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            if (downloadedTrack != null)
                                              SvgPicture.asset(
                                                "assets/icons/download2.svg",
                                                width: 14,
                                                height: 14,
                                              ),
                                            if (downloadedTrack != null)
                                              const SizedBox(width: 4),
                                            Expanded(
                                              child: ArtistsLinksText(
                                                artists: track.artists,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  letterSpacing: 14 * 0.03,
                                                  color: Colors.grey[350],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        case DesktopTrackModule.album:
                          yield Expanded(
                            child: IntrinsicWidth(
                              child: AlbumLinkText(
                                text: track.album,
                                albumId: track.albumId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 14 * 0.03,
                                  color: Colors.grey[350],
                                ),
                              ),
                            ),
                          );
                        case DesktopTrackModule.lastPlayed:
                          yield SizedBox(
                            width: module.width,
                            child: track.historyInfo?.lastPlayedDate == null
                                ? Text(
                                    "Never",
                                    style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 14 * 0.03,
                                      color: Colors.grey[350],
                                    ),
                                  )
                                : FormatTimeago(
                                    date: track.historyInfo!.lastPlayedDate!,
                                    builder: (context, value) {
                                      return Text(
                                        value,
                                        style: TextStyle(
                                          fontSize: 12,
                                          letterSpacing: 14 * 0.03,
                                          color: Colors.grey[350],
                                        ),
                                      );
                                    },
                                  ),
                          );
                        case DesktopTrackModule.playedCount:
                          yield SizedBox(
                            width: module.width,
                            child: Text(
                              track.historyInfo?.playedCount == 0
                                  ? "Never"
                                  : "${track.historyInfo?.playedCount}",
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 14 * 0.03,
                                color: Colors.grey[350],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        case DesktopTrackModule.dateAdded:
                          yield SizedBox(
                            width: module.width,
                            child: FormatTimeago(
                              date: track.dateAdded,
                              builder: (context, value) => Text(
                                value,
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 14 * 0.03,
                                  color: Colors.grey[350],
                                ),
                              ),
                            ),
                          );
                        case DesktopTrackModule.quality:
                          yield SizedBox(
                            width: module.width,
                            child: Text(
                              track.getQualityText(),
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 14 * 0.03,
                                color: Colors.grey[350],
                              ),
                            ),
                          );
                        case DesktopTrackModule.score:
                          yield TrackScore(track: track);
                        case DesktopTrackModule.duration:
                          yield SizedBox(
                            width: module.width,
                            child: Text(
                              durationToTime(track.duration),
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: 14 * 0.03,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        case DesktopTrackModule.moreActions:
                          yield SizedBox(
                            width: module.width,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {},
                                onDoubleTap: () {},
                                child: Listener(
                                  onPointerDown: (_) {
                                    final callback = selectCallback;

                                    if (callback != null) {
                                      callback(track);
                                    }
                                  },
                                  child: ContextMenuButton(
                                    contextMenuKey: trackContextMenuKey,
                                    menuController: trackContextMenuController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    direction: Axis.vertical,
                                  ),
                                ),
                              ),
                            ),
                          );
                        case DesktopTrackModule.reorderable:
                          yield SizedBox(
                            width: module.width,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {},
                                onDoubleTap: () {},
                                child: ReorderableListener(
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    color: Colors.transparent,
                                    child: const MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: Padding(
                                        padding: EdgeInsets.all(4.0),
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
                            ),
                          );
                      }

                      if (module.rightPadding != 0) {
                        yield SizedBox(
                          width: module.rightPadding,
                        );
                      }
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    if (!isServerReachable && downloadedTrack == null) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.4,
          child: trackWidget,
        ),
      );
    }

    return trackWidget;
  }
}
