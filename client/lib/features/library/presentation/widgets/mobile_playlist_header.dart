import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/duration_to_human.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class MobilePlaylistHeader extends ConsumerWidget {
  final String name;
  final String type;
  final String imageUrl;

  final List<MinimalTrack> tracks;

  final String artist;

  final VoidCallback playCallback;

  final VoidCallback downloadCallback;

  final bool downloaded;

  const MobilePlaylistHeader({
    super.key,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.tracks,
    required this.artist,
    required this.playCallback,
    required this.downloadCallback,
    required this.downloaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 48.0,
              vertical: 6.0,
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: AuthCachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => Image.asset(
                  "assets/melodink_track_cover_not_found.png",
                ),
                errorWidget: (context, url, error) {
                  return Image.asset(
                    "assets/melodink_track_cover_not_found.png",
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  letterSpacing: 20 * 0.03,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: artist,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 14 * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: [
                        if (artist.isNotEmpty) "",
                        "${tracks.length} Track${tracks.length > 1 ? 's' : ''}",
                        durationToHuman(
                          tracks.fold(
                            Duration.zero,
                            (sum, activity) => sum + activity.duration,
                          ),
                        )
                      ].join(" • "),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 12 * 0.03,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[350],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppIconButton(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                icon: downloaded
                    ? SvgPicture.asset(
                        "assets/icons/download2.svg",
                        width: 20,
                        height: 20,
                      )
                    : SvgPicture.asset(
                        "assets/icons/download.svg",
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                iconSize: 20.0,
                onPressed: downloadCallback,
              ),
              AppIconButton(
                padding: const EdgeInsets.all(8),
                icon: const AdwaitaIcon(
                  AdwaitaIcons.view_more_horizontal,
                ),
                color: Colors.white,
                iconSize: 20.0,
                onPressed: () async {},
              ),
              const Spacer(),
              StreamBuilder(
                stream: audioController.playbackState,
                builder: (context, snapshot) {
                  return AppIconButton(
                    padding: const EdgeInsets.all(8),
                    icon: const AdwaitaIcon(
                      AdwaitaIcons.media_playlist_shuffle,
                    ),
                    color: snapshot.data?.shuffleMode ==
                            AudioServiceShuffleMode.all
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    iconSize: 20.0,
                    onPressed: () async {
                      await audioController.toogleShufle();
                    },
                  );
                },
              ),
              AppIconButton(
                onPressed: playCallback,
                padding: const EdgeInsets.only(left: 8),
                iconSize: 40,
                icon: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC47ED0),
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: const Center(
                    child: AdwaitaIcon(
                      size: 24,
                      AdwaitaIcons.media_playback_start,
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
