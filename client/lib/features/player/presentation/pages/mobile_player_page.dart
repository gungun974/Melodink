import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:melodink_client/core/helpers/is_touch_device.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/context_menu_button.dart';
import 'package:melodink_client/core/widgets/dismissible_page.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/like_track_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/controls/open_queue_control.dart';
import 'package:melodink_client/features/player/presentation/widgets/large_player_seeker.dart';
import 'package:melodink_client/features/player/presentation/widgets/live_lyrics.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_controls.dart';
import 'package:melodink_client/features/player/presentation/widgets/player_error_overlay.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/hooks/use_get_download_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/album_link_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';
import 'package:melodink_client/features/track/presentation/widgets/single_track_context_menu.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class MobilePlayerPage extends HookWidget {
  const MobilePlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    final trackContextMenuController = useMemoized(() => MenuController());

    final trackContextMenuKey = useMemoized(() => GlobalKey());

    final scrollController = useScrollController();
    final liveLyricsKey = useMemoized(() => GlobalKey());

    return DismissiblePage(
      key: const Key('DesktopPlayerPageDown'),
      active: isTouchDevice(context),
      onDismissed: () => Navigator.of(context).pop(),
      builder: (context, isDismissActive) {
        return Stack(
          children: [
            const GradientBackground(),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                leading: IconButton(
                  icon: SvgPicture.asset(
                    "assets/icons/arrow-down.svg",
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  ContextMenuButton(
                    contextMenuKey: trackContextMenuKey,
                    menuController: trackContextMenuController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ],
                title: StreamBuilder<String?>(
                  stream: audioController.playerTracksFrom.stream,
                  builder: (context, snapshot) {
                    final source = snapshot.data;
                    if (source == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      source,
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 20 * 0.03,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
                centerTitle: true,
                backgroundColor: const Color.fromRGBO(0, 0, 0, 0.08),
                shadowColor: Colors.transparent,
              ),
              body: LayoutBuilder(
                builder: (context, layout) {
                  return LiveLyricsController(
                    startWithAutoLyrics: false,
                    liveLyricsKey: liveLyricsKey,
                    scrollController: scrollController,
                    builder: (_, autoScrollToLyric, setShouldDisableAutoScrollOnScroll) {
                      return CustomScrollView(
                        controller: scrollController,
                        physics: isDismissActive
                            ? const NeverScrollableScrollPhysics()
                            : const ScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: IntrinsicHeight(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: layout.maxHeight,
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 8.0,
                                        ),
                                        constraints: const BoxConstraints(
                                          maxWidth: 512,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            StreamBuilder(
                                              stream: audioController
                                                  .currentTrack
                                                  .stream,
                                              builder: (context, snapshot) {
                                                audioController
                                                    .previousTracks
                                                    .valueOrNull
                                                    ?.take(5)
                                                    .forEach((track) {
                                                      ImageCacheManager.preCache(
                                                        track.getCompressedCoverUri(
                                                          TrackCompressedCoverQuality
                                                              .high,
                                                        ),
                                                        context,
                                                      );
                                                    });

                                                audioController
                                                    .nextTracks
                                                    .valueOrNull
                                                    ?.take(5)
                                                    .forEach((track) {
                                                      ImageCacheManager.preCache(
                                                        track.getCompressedCoverUri(
                                                          TrackCompressedCoverQuality
                                                              .high,
                                                        ),
                                                        context,
                                                      );
                                                    });

                                                return _MobilePlayerInfo(
                                                  trackContextMenuKey:
                                                      trackContextMenuKey,
                                                  trackContextMenuController:
                                                      trackContextMenuController,
                                                  snapshot: snapshot,
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            const Column(
                                              children: [
                                                LargePlayerSeeker(
                                                  displayDurationsInBottom:
                                                      true,
                                                  large: true,
                                                ),
                                                PlayerControls(
                                                  largeControlsButton: true,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        right: 16.0,
                                        bottom: 16.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Spacer(),
                                          OpenQueueControl(
                                            largeControlButton: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Consumer<List<LyricLine>?>(
                            builder: (context, viewModel, _) {
                              if (viewModel == null) {
                                return SliverToBoxAdapter();
                              }
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    t.general.lyrics,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      letterSpacing: 40 * 0.03,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Consumer<List<LyricLine>?>(
                            builder: (context, viewModel, _) {
                              if (viewModel == null) {
                                return SliverToBoxAdapter();
                              }
                              return SliverPadding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 16.0,
                                ),
                                sliver: LiveLyrics(
                                  key: liveLyricsKey,
                                  autoScrollToLyric: autoScrollToLyric,
                                  scrollController: scrollController,
                                  setShouldDisableAutoScrollOnScroll:
                                      setShouldDisableAutoScrollOnScroll,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MobilePlayerInfo extends StatelessWidget {
  const _MobilePlayerInfo({
    required this.trackContextMenuKey,
    required this.trackContextMenuController,
    required this.snapshot,
  });

  final GlobalKey<State<StatefulWidget>> trackContextMenuKey;
  final MenuController trackContextMenuController;
  final AsyncSnapshot<Track?> snapshot;

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final scoringSystem = context
            .watch<SettingsViewModel>()
            .currentScoringSystem();

        final currentTrack = snapshot.data;

        if (currentTrack == null) {
          return const SizedBox.shrink();
        }

        final downloadedTrack = useGetDownloadTrack(context, currentTrack.id);

        final image = PlayerErrorOverlay(
          child: AuthCachedNetworkImage(
            fit: BoxFit.contain,
            imageUrl:
                downloadedTrack?.getCoverUrl() ??
                currentTrack.getCompressedCoverUrl(
                  TrackCompressedCoverQuality.high,
                ),
            placeholder: (context, url) =>
                Image.asset("assets/melodink_track_cover_not_found.png"),
            errorWidget: (context, url, error) {
              return Image.asset("assets/melodink_track_cover_not_found.png");
            },
            gaplessPlayback: true,
          ),
        );

        return SingleTrackContextMenu(
          key: trackContextMenuKey,
          track: currentTrack,
          menuController: trackContextMenuController,
          child: Column(
            children: [
              IgnorePointer(
                child: Row(
                  children: [
                    Expanded(
                      child: AspectRatio(aspectRatio: 1.0, child: image),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AlbumLinkText(
                          text: currentTrack.title,
                          albumId: currentTrack.albums.firstOrNull?.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: 16 * 0.03,
                          ),
                          openWithScrollOnSpecificTrackId: currentTrack.id,
                        ),
                        const SizedBox(height: 4),
                        ArtistsLinksText(
                          artists: currentTrack.artists,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 14 * 0.03,
                            color: Colors.grey[350],
                          ),
                        ),
                        const SizedBox(height: 4),
                        AlbumLinkText(
                          text: currentTrack.albums
                              .map((album) => album.name)
                              .join(", "),
                          albumId: currentTrack.albums.firstOrNull?.id,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 12 * 0.03,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[350],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (scoringSystem != AppSettingScoringSystem.none)
                    CurrentTrackScoreControl(largeControlButton: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
