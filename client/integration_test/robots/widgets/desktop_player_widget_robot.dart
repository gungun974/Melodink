import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodink_client/features/player/presentation/widgets/desktop/desktop_player_widget.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';

import '../../helpers/wait_for_widget.dart';

class DesktopPlayerWidgetRobot {
  final WidgetTester tester;
  DesktopPlayerWidgetRobot({required this.tester});

  Future<void> playOrPausePlayer() async {
    await tester.tap(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('playButton'),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 10));
  }

  Future<void> assertPlayerPause() async {
    await tester.pumpAndSettle(const Duration(milliseconds: 10));

    final playButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('playButton'),
        ),
      ),
    );

    expect(
      playButton.icon,
      isA<AdwaitaIcon>(),
    );

    expect(
      (playButton.icon as AdwaitaIcon).asset,
      equals(AdwaitaIcons.media_playback_start),
    );
  }

  Future<void> assertPlayerPlay() async {
    await tester.pumpAndSettle(const Duration(milliseconds: 10));

    final playButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('playButton'),
        ),
      ),
    );

    expect(
      playButton.icon,
      isA<AdwaitaIcon>(),
    );

    expect(
      (playButton.icon as AdwaitaIcon).asset,
      equals(AdwaitaIcons.media_playback_pause),
    );
  }

  Future<void> assertPlayerDuration(String duration) async {
    final positionTextFinder = find.descendant(
      of: find.byType(DesktopPlayerWidget),
      matching: find.byKey(
        const Key('positionText'),
      ),
    );

    await waitForWidgetWithText(
      tester,
      positionTextFinder,
      duration,
      timeout: const Duration(seconds: 2),
    );

    final positionText = tester.widget<Text>(
      positionTextFinder,
    );

    expect(
      positionText.data,
      equals(duration),
    );
  }

  Future<void> assertCurrentTrack(Track track) async {
    final desktopPlayerWidgetFinder = find.byType(DesktopPlayerWidget);

    expect(desktopPlayerWidgetFinder, findsOneWidget);

    final titleTextFinder = find.descendant(
      of: desktopPlayerWidgetFinder,
      matching: find.byKey(
        const Key('titleText'),
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));

    await waitForWidgetWithText(
      tester,
      titleTextFinder,
      track.title,
      timeout: const Duration(seconds: 5),
    );

    Text titleText = tester.widget<Text>(titleTextFinder);

    Text artistText = tester.widget<Text>(find.descendant(
      of: desktopPlayerWidgetFinder,
      matching: find.byKey(const Key("artistText")),
    ));

    expect(
      titleText.data,
      equals(track.title),
    );

    expect(
      artistText.data,
      equals(track.metadata.artist),
    );
  }

  Future<void> skipToNext() async {
    await tester.tap(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('nextButton'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> skipToPrevious() async {
    await tester.tap(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('previousButton'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> tapRepeatButton() async {
    await tester.tap(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('repeatButton'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> assertRepeatOff() async {
    await tester.pumpAndSettle(const Duration(milliseconds: 10));

    final playButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('repeatButton'),
        ),
      ),
    );

    expect(
      playButton.icon,
      isA<AdwaitaIcon>(),
    );

    expect(
      (playButton.icon as AdwaitaIcon).asset,
      equals(AdwaitaIcons.media_playlist_repeat),
    );

    expect(
      playButton.color,
      equals(Colors.white),
    );
  }

  Future<void> assertRepeatAll() async {
    await tester.pumpAndSettle(const Duration(milliseconds: 10));

    final playButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('repeatButton'),
        ),
      ),
    );

    expect(
      playButton.icon,
      isA<AdwaitaIcon>(),
    );

    expect(
      (playButton.icon as AdwaitaIcon).asset,
      equals(AdwaitaIcons.media_playlist_repeat),
    );

    expect(
      playButton.color,
      isNot(equals(Colors.white)),
    );
  }

  Future<void> assertRepeatOne() async {
    await tester.pumpAndSettle(const Duration(milliseconds: 10));

    final playButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('repeatButton'),
        ),
      ),
    );

    expect(
      playButton.icon,
      isA<AdwaitaIcon>(),
    );

    expect(
      (playButton.icon as AdwaitaIcon).asset,
      equals(AdwaitaIcons.media_playlist_repeat_song),
    );

    expect(
      playButton.color,
      isNot(equals(Colors.white)),
    );
  }

  Future<void> tapShuffleButton() async {
    await tester.tap(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('shuffleButton'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> assertShuffleOff() async {
    await tester.pumpAndSettle(const Duration(milliseconds: 10));

    final playButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('shuffleButton'),
        ),
      ),
    );

    expect(
      playButton.icon,
      isA<AdwaitaIcon>(),
    );

    expect(
      (playButton.icon as AdwaitaIcon).asset,
      equals(AdwaitaIcons.media_playlist_shuffle),
    );

    expect(
      playButton.color,
      equals(Colors.white),
    );
  }

  Future<void> assertShuffleOn() async {
    await tester.pumpAndSettle(const Duration(milliseconds: 10));

    final playButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(DesktopPlayerWidget),
        matching: find.byKey(
          const Key('shuffleButton'),
        ),
      ),
    );

    expect(
      playButton.icon,
      isA<AdwaitaIcon>(),
    );

    expect(
      (playButton.icon as AdwaitaIcon).asset,
      equals(AdwaitaIcons.media_playlist_shuffle),
    );

    expect(
      playButton.color,
      isNot(equals(Colors.white)),
    );
  }
}
