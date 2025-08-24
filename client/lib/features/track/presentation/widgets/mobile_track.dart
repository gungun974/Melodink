import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:melodink_client/core/helpers/is_touch_device.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/context_menu_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/hooks/use_get_download_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_context_menu.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MobileTrack extends HookWidget {
  final Track track;

  final void Function(Track track) playCallback;

  final bool showImage;

  final bool displayRemove;
  final bool displayMoreActions;
  final bool displayReorderable;

  final void Function(Track track)? selectCallback;

  final bool selected;
  final bool selectedTop;
  final bool selectedBottom;

  final List<Track> selectedTracks;

  final void Function(Track track)? removeCallback;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    Track track,
  )?
  singleCustomActionsBuilder;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    List<Track> tracks,
  )?
  multiCustomActionsBuilder;

  final bool showDefaultActions;

  const MobileTrack({
    super.key,
    required this.track,
    required this.playCallback,
    this.showImage = true,
    this.displayRemove = false,
    this.displayMoreActions = true,
    this.displayReorderable = false,
    this.selectCallback,
    this.selected = false,
    this.selectedTop = true,
    this.selectedBottom = true,
    this.selectedTracks = const [],
    this.removeCallback,
    this.singleCustomActionsBuilder,
    this.multiCustomActionsBuilder,
    this.showDefaultActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.watch<SettingsViewModel>().currentAppTheme();

    final isServerReachable = context.select<NetworkInfo, bool>(
      (networkInfo) => networkInfo.isServerRecheable(),
    );

    final audioController = context.read<AudioController>();

    final isCurrentTrack =
        useStream(
          useMemoized(
            () => audioController.currentTrack.stream
                .startWith(audioController.currentTrack.valueOrNull)
                .map((currentTrack) => currentTrack?.id == track.id),
            [track.id],
          ),
        ).data ??
        false;

    final asyncDownloadedTrack = useAsyncGetDownloadTrack(context, track.id);

    final downloadedTrack = asyncDownloadedTrack.data;

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
            showDefaultActions: showDefaultActions,
            singleCustomActionsBuilder: singleCustomActionsBuilder,
            multiCustomActionsBuilder: multiCustomActionsBuilder,
            child: Container(
              height: 50,
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: selected
                    ? (currentTheme == AppSettingTheme.dark
                          ? const Color.fromRGBO(160, 160, 160, 0.139)
                          : const Color.fromRGBO(0, 0, 0, 0.139))
                    : (isHovering.value
                          ? (currentTheme == AppSettingTheme.dark
                                ? const Color.fromRGBO(160, 160, 160, 0.05)
                                : const Color.fromRGBO(0, 0, 0, 0.05))
                          : Colors.transparent),
                borderRadius: BorderRadius.vertical(
                  top: selectedTop ? const Radius.circular(8) : Radius.zero,
                  bottom: selectedBottom
                      ? const Radius.circular(8)
                      : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  if (displayRemove)
                    GestureDetector(
                      onTap: () {},
                      child: Listener(
                        onPointerDown: (_) {
                          removeCallback?.call(track);
                        },
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.only(right: 8.0),
                          color: Colors.transparent,
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: AdwaitaIcon(AdwaitaIcons.list_remove),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showImage &&
                              asyncDownloadedTrack.connectionState ==
                                  ConnectionState.done)
                            AuthCachedNetworkImage(
                              imageUrl:
                                  downloadedTrack?.getCoverUrl() ??
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
                                  waitDuration: const Duration(
                                    milliseconds: 800,
                                  ),
                                  child: Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      letterSpacing: 14 * 0.03,
                                      fontWeight: FontWeight.w500,
                                      color: isCurrentTrack
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
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
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          direction: Axis.vertical,
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
      return IgnorePointer(child: Opacity(opacity: 0.4, child: trackWidget));
    }

    return trackWidget;
  }
}
