import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/is_touch_device.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/context_menu_button.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_context_menu.dart';

class MobileTrack extends HookConsumerWidget {
  final MinimalTrack track;

  final void Function(MinimalTrack track) playCallback;

  final bool showImage;

  final bool displayMoreActions;
  final bool displayReorderable;

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

  const MobileTrack({
    super.key,
    required this.track,
    required this.playCallback,
    this.showImage = true,
    this.displayMoreActions = true,
    this.displayReorderable = false,
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
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: selected
                    ? const Color.fromRGBO(0, 0, 0, 0.075)
                    : (isHovering.value
                        ? const Color.fromRGBO(0, 0, 0, 0.05)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showImage)
                            AuthCachedNetworkImage(
                              imageUrl: downloadedTrack?.getCoverUrl() ??
                                  track.getCompressedCoverUrl(
                                    TrackCompressedCoverQuality.small,
                                  ),
                              placeholder: (context, url) => Image.asset(
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        noInteraction: true,
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
                  ),
                  if (displayMoreActions)
                    GestureDetector(
                      onTap: () {},
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
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                          ),
                        ),
                      ),
                    ),
                  if (displayReorderable)
                    GestureDetector(
                      onTap: () {},
                      child: ReorderableListener(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.only(left: 16, right: 12),
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
