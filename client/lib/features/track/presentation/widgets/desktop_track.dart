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
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/widgets/album_link_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_context_menu.dart';
import 'package:melodink_client/features/tracker/domain/providers/played_track_provider.dart';

class DesktopTrack extends HookConsumerWidget {
  final MinimalTrack track;

  final int trackNumber;
  final bool displayDateAdded;

  final bool displayImage;
  final bool displayAlbum;

  final bool displayLike;
  final bool displayMoreActions;
  final bool displayReorderable;

  final bool displayLastPlayed;
  final bool displayPlayedCount;
  final bool displayQuality;

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
    this.displayDateAdded = false,
    this.displayImage = true,
    this.displayAlbum = true,
    this.displayLike = true,
    this.displayMoreActions = true,
    this.displayReorderable = false,
    this.displayLastPlayed = false,
    this.displayPlayedCount = false,
    this.displayQuality = false,
    this.selectCallback,
    this.selected = false,
    this.selectedTracks = const [],
    this.singleCustomActionsBuilder,
    this.multiCustomActionsBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentTrack = ref.watch(isCurrentTrackProvider(track.id));

    final downloadedTrack = ref
        .watch(
          isTrackDownloadedProvider(track.id),
        )
        .valueOrNull;

    final lastPlayedDate = ref
        .watch(
          lastPlayedTrackDateProvider(track.id),
        )
        .valueOrNull;

    final trackPlayedCount = ref
        .watch(
          trackPlayedCountProvider(track.id),
        )
        .valueOrNull;

    final trackContextMenuController = useMemoized(() => MenuController());

    final tracksContextMenuController = useMemoized(() => MenuController());

    final trackContextMenuKey = useMemoized(() => GlobalKey());

    final isHovering = useState(false);

    return MouseRegion(
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
              child: Row(
                children: [
                  SizedBox(
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
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (displayImage)
                            AuthCachedNetworkImage(
                              imageUrl: downloadedTrack?.getCoverUrl() ??
                                  track.getCoverUrl(),
                              placeholder: (context, url) => Image.asset(
                                "assets/melodink_track_cover_not_found.png",
                              ),
                              errorWidget: (context, url, error) {
                                return Image.asset(
                                  "assets/melodink_track_cover_not_found.png",
                                );
                              },
                            ),
                          if (displayImage) const SizedBox(width: 10),
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
                  const SizedBox(width: 24),
                  if (displayAlbum)
                    Expanded(
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
                    ),
                  if (displayLastPlayed) const SizedBox(width: 8),
                  if (displayLastPlayed)
                    SizedBox(
                      width: 96,
                      child: Text(
                        lastPlayedDate == null
                            ? "Never"
                            : formatTimeago(lastPlayedDate),
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 14 * 0.03,
                          color: Colors.grey[350],
                        ),
                      ),
                    ),
                  if (displayPlayedCount)
                    SizedBox(
                      width: 40,
                      child: Text(
                        trackPlayedCount == 0 ? "Never" : "$trackPlayedCount",
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 14 * 0.03,
                          color: Colors.grey[350],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  if (displayPlayedCount) const SizedBox(width: 24),
                  if (displayDateAdded)
                    SizedBox(
                      width: 96,
                      child: Text(
                        formatTimeago(track.dateAdded),
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 14 * 0.03,
                          color: Colors.grey[350],
                        ),
                      ),
                    ),
                  if (displayDateAdded && !displayQuality)
                    const SizedBox(width: 24),
                  if (displayQuality)
                    SizedBox(
                      width: 128,
                      child: Text(
                        track.getQualityText(),
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 14 * 0.03,
                          color: Colors.grey[350],
                        ),
                      ),
                    ),
                  if (displayQuality) const SizedBox(width: 24),
                  SizedBox(
                    width: 60,
                    child: Text(
                      durationToTime(track.duration),
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 14 * 0.03,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (displayLike)
                    GestureDetector(
                      onTap: () {},
                      onDoubleTap: () {},
                      child: Container(
                        height: 50,
                        color: Colors.transparent,
                        child: AppIconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          icon: const AdwaitaIcon(
                              AdwaitaIcons.heart_outline_thick),
                          iconSize: 20.0,
                          onPressed: () async {},
                        ),
                      ),
                    ),
                  if (displayMoreActions)
                    GestureDetector(
                      onTap: () {},
                      onDoubleTap: () {},
                      child: TrackContextMenuButton(
                        trackContextMenuKey: trackContextMenuKey,
                        menuController: trackContextMenuController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                    ),
                  if (displayReorderable)
                    GestureDetector(
                      onTap: () {},
                      onDoubleTap: () {},
                      child: ReorderableListener(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
