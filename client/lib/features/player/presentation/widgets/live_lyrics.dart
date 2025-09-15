import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/helpers/debounce.dart';
import 'package:melodink_client/core/hooks/use_behavior_subject_stream.dart';
import 'package:melodink_client/core/hooks/use_list_controller.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:provider/provider.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class LiveLyrics extends HookWidget {
  final ScrollController? scrollController;

  final bool autoScrollToLyric;

  final void Function(bool value)? setShouldDisableAutoScrollOnScroll;

  const LiveLyrics({
    super.key,
    this.autoScrollToLyric = true,
    this.scrollController,
    this.setShouldDisableAutoScrollOnScroll,
  });

  @override
  Widget build(BuildContext context) {
    final listController = useListController();
    final currentAutoScrollIndex = useState<int?>(null);

    final autoScrollDebouncer = useMemoized(() => Debouncer(milliseconds: 350));

    final lyrics = context.watch<List<LyricLine>?>();

    useEffect(() {
      if (!autoScrollToLyric) {
        currentAutoScrollIndex.value = null;
      }
      return null;
    }, [autoScrollToLyric]);

    if (lyrics == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final audioController = context.read<AudioController>();

    final audioControllerPositionDataStream = useBehaviorSubjectStream(
      audioController.getPositionData(),
    );
    final positionData = audioControllerPositionDataStream.data;

    final position = positionData?.position ?? Duration.zero;

    useOnStreamChange(
      audioController.getPositionData().stream,
      onData: (newPositionData) {
        if (!autoScrollToLyric) {
          return;
        }

        final position = newPositionData.position;

        int? currentIndex;

        for (var i = 0; i < lyrics.length; i++) {
          final lyric = lyrics[i];

          if (!lyric.timed) {
            return;
          }

          final nextLyric = i + 1 < lyrics.length ? lyrics[i + 1] : null;

          final isNext = lyric.timestamp > position;
          final isCurrent =
              !isNext && (nextLyric == null || nextLyric.timestamp > position);

          if (isCurrent) {
            currentIndex = i;
            break;
          }
        }

        if (currentIndex == null) {
          return;
        }

        if (currentAutoScrollIndex.value == currentIndex) {
          return;
        }

        setShouldDisableAutoScrollOnScroll?.call(false);

        listController.animateToItem(
          index: currentIndex,
          scrollController: scrollController!,
          alignment: 0.35,
          curve: (_) => Curves.easeInOutCubic,
          duration: (_) => const Duration(milliseconds: 300),
        );

        autoScrollDebouncer.run(() {
          setShouldDisableAutoScrollOnScroll?.call(true);
        });

        currentAutoScrollIndex.value = currentIndex;
      },
    );

    return SuperSliverList(
      extentEstimation: (_, _) => 50,
      listController: scrollController != null ? listController : null,
      delegate: SliverChildBuilderDelegate(childCount: lyrics.length, (
        context,
        index,
      ) {
        final lyric = lyrics[index];
        final nextLyric = index + 1 < lyrics.length ? lyrics[index + 1] : null;

        final isNext = lyric.timestamp > position;
        final isCurrent =
            !isNext && (nextLyric == null || nextLyric.timestamp > position);

        return Row(
          children: [
            Flexible(
              child: HookBuilder(
                builder: (context) {
                  final isHovering = useState(false);

                  return MouseRegion(
                    cursor: lyric.timed
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    onEnter: (_) {
                      isHovering.value = true;
                    },
                    onExit: (_) {
                      isHovering.value = false;
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (!lyric.timed) {
                          return;
                        }
                        audioController.seek(lyric.timestamp);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          lyric.text,
                          style: TextStyle(
                            fontSize: 24,
                            letterSpacing: 24 * 0.05,
                            fontWeight: isCurrent
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: isCurrent || isHovering.value || !lyric.timed
                                ? Colors.white
                                : (isNext ? Colors.white70 : Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class LyricLine {
  final Duration timestamp;
  final String text;
  final bool timed;

  LyricLine(this.timestamp, this.text, this.timed);

  @override
  String toString() {
    return '[${timestamp.toString().split('.').first}] $text';
  }
}

class LyricsParser {
  static List<LyricLine> parse(String lyrics) {
    final List<LyricLine> parsedLyrics = [];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]\s*(.*)');

    for (final line in lyrics.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!) * 10;
        final text = match.group(4) ?? '';

        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        parsedLyrics.add(LyricLine(timestamp, text, true));
      }
    }

    return parsedLyrics;
  }
}

class LiveLyricsController extends HookWidget {
  final Widget Function(
    BuildContext context,
    bool autoScrollToLyric,
    void Function(bool value) setShouldDisableAutoScrollOnScroll,
  )
  builder;

  final ScrollController scrollController;

  final GlobalKey? liveLyricsKey;

  final bool startWithAutoLyrics;

  const LiveLyricsController({
    super.key,
    required this.builder,
    required this.scrollController,
    this.liveLyricsKey,
    this.startWithAutoLyrics = true,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    final currentLyrics = useStream(
      useMemoized(
        () => audioController.currentTrack.stream.map((currentTrack) {
          if (currentTrack == null) {
            return null;
          }

          final lyrics = currentTrack.metadata.lyrics;

          if (lyrics.trim().isEmpty) {
            return null;
          }

          final parsed = LyricsParser.parse(lyrics);

          if (parsed.isEmpty) {
            return [LyricLine(Duration.zero, lyrics, false)];
          }

          return parsed;
        }),
      ),
    ).data;

    final autoScrollToLyric = useState(startWithAutoLyrics);
    final shouldDisableAutoScrollOnScroll = useState(true);

    final shouldDisplayAutoScrollButton = useState(false);

    void onScroll() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (liveLyricsKey != null && liveLyricsKey!.currentWidget != null) {
          final RenderSliver renderObject =
              liveLyricsKey!.currentContext!.findRenderObject() as RenderSliver;
          final SliverGeometry geometry = renderObject.geometry!;

          shouldDisplayAutoScrollButton.value = geometry.paintExtent > 10;
        }
      });

      if (!shouldDisableAutoScrollOnScroll.value) {
        return;
      }

      double offset = scrollController.offset;

      if (offset > 10) {
        autoScrollToLyric.value = false;
      }
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

    final displayButton =
        !autoScrollToLyric.value &&
        shouldDisplayAutoScrollButton.value &&
        currentLyrics != null;

    return Stack(
      children: [
        Provider.value(
          value: currentLyrics,
          child: builder(context, autoScrollToLyric.value, (bool value) {
            shouldDisableAutoScrollOnScroll.value = value;
          }),
        ),
        IgnorePointer(
          ignoring: !displayButton,
          child: AnimatedOpacity(
            opacity: displayButton ? 1 : 0,
            duration: const Duration(milliseconds: 100),
            child: Align(
              alignment: Alignment.bottomRight,
              child: AppIconButton(
                onPressed: () {
                  autoScrollToLyric.value = true;
                },
                padding: const EdgeInsets.all(8),
                iconSize: 48,
                icon: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC47ED0),
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: const Center(
                    child: AdwaitaIcon(
                      size: 20,
                      AdwaitaIcons.emblem_synchronizing,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
