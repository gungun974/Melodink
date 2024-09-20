import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/helpers/timeago.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class DesktopTrack extends ConsumerWidget {
  final MinimalTrack track;

  final int trackNumber;
  final bool displayDateAdded;

  final bool displayImage;
  final bool displayAlbum;

  final void Function(MinimalTrack track) playCallback;

  const DesktopTrack({
    super.key,
    required this.track,
    required this.trackNumber,
    required this.playCallback,
    this.displayDateAdded = false,
    this.displayImage = true,
    this.displayAlbum = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentTrack = ref.watch(isCurrentTrackProvider(track.id));

    return GestureDetector(
      onTap: () {
        playCallback(track);
      },
      child: SizedBox(
        height: 50,
        child: Container(
          color: Colors.transparent,
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 14 * 0.03,
                              fontWeight: FontWeight.w500,
                              color: isCurrentTrack
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
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
                    ],
                  ),
                ),
              ),
              if (displayAlbum)
                Expanded(
                  child: Text(
                    track.album,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 14 * 0.03,
                      color: Colors.grey[350],
                    ),
                  ),
                ),
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
              if (displayDateAdded) const SizedBox(width: 24),
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
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 50,
                  color: Colors.transparent,
                  child: AppIconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    icon: const AdwaitaIcon(AdwaitaIcons.heart_outline_thick),
                    iconSize: 20.0,
                    onPressed: () async {},
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
