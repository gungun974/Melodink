import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_context_menu.dart';

class MobileTrack extends HookConsumerWidget {
  final MinimalTrack track;

  final void Function(MinimalTrack track) playCallback;

  final bool displayImage;

  final bool displayMoreActions;
  final bool displayReorderable;

  const MobileTrack({
    super.key,
    required this.track,
    required this.playCallback,
    this.displayImage = true,
    this.displayMoreActions = true,
    this.displayReorderable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentTrack = ref.watch(isCurrentTrackProvider(track.id));

    final menuController = useMemoized(() => MenuController());

    final trackContextMenuKey = useMemoized(() => GlobalKey());

    return GestureDetector(
      onTap: () {
        playCallback(track);
      },
      child: TrackContextMenu(
        key: trackContextMenuKey,
        track: track,
        menuController: menuController,
        child: Container(
          height: 50,
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (displayImage)
                        AuthCachedNetworkImage(
                          imageUrl: track.getCoverUrl(),
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
                              waitDuration: const Duration(milliseconds: 800),
                              child: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (track.downloadedTrack != null)
                                  SvgPicture.asset(
                                    "assets/icons/download2.svg",
                                    width: 14,
                                    height: 14,
                                  ),
                                if (track.downloadedTrack != null)
                                  const SizedBox(width: 4),
                                Text(
                                  track.getVirtualAlbumArtist(),
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
                    ],
                  ),
                ),
              ),
              if (displayMoreActions)
                TrackContextMenuButton(
                  trackContextMenuKey: trackContextMenuKey,
                  menuController: menuController,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 4,
                  ),
                ),
              if (displayReorderable)
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
