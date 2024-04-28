import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodink_client/features/playlist/presentation/widgets/playlist_info_header.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/features/tracks/presentation/widgets/tracks_list.dart';
import 'package:melodink_client/routes.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../helpers/async_wait.dart';
import '../../helpers/get_screen_type.dart';

class AllTracksPageRobot {
  final WidgetTester tester;
  AllTracksPageRobot({required this.tester});

  Future<void> goto() async {
    appRouter.go("/tracks");

    await tester.pumpAndSettle(const Duration(milliseconds: 10));
  }

  Future<void> ensureTracksPage() async {
    if (appRouter.location != "/tracks") {
      appRouter.go("/tracks");

      await tester.pumpAndSettle(const Duration(milliseconds: 10));
    }
  }

  Future<void> assertCurrentPage() async {
    expect(appRouter.location, equals("/tracks"));

    if (getScreenType(tester) == DeviceScreenType.desktop) {
      final tracksInfoHeader = find.byType(TracksInfoHeader);

      expect(tracksInfoHeader, findsOneWidget);

      final playlistTitle = find.descendant(
        of: tracksInfoHeader,
        matching: find.text("All tracks"),
      );

      expect(playlistTitle, findsAtLeast(1));
    }
  }

  Future<void> assertPlaylistNumberOfTracks(int number) async {
    await ensureTracksPage();

    if (getScreenType(tester) == DeviceScreenType.desktop) {
      final tracksInfoHeader = find.byType(TracksInfoHeader);

      expect(tracksInfoHeader, findsOneWidget);

      final numberOfTracksText = find.descendant(
        of: tracksInfoHeader,
        matching: switch (number) {
          0 => find.textContaining("Empty"),
          1 => find.textContaining("1 track"),
          _ => find.textContaining("$number tracks"),
        },
      );

      expect(numberOfTracksText, findsOneWidget);
    }
  }

  Future<void> assertTrackPresentAtPosition(Track track, int pos) async {
    await ensureTracksPage();

    final tracksList = find.byType(TracksList);

    expect(tracksList, findsOneWidget);

    final trackRow = find.descendant(
      of: tracksList,
      matching: find.byKey(Key("trackRow[$pos]")),
    );

    expect(trackRow, findsOneWidget);

    Text titleText = tester.widget<Text>(find.descendant(
      of: trackRow,
      matching: find.byKey(const Key("titleText")),
    ));

    expect(
      titleText.data,
      equals(track.title),
    );

    Text artistText = tester.widget<Text>(find.descendant(
      of: trackRow,
      matching: find.byKey(const Key("artistText")),
    ));

    expect(
      artistText.data,
      equals(track.metadata.artist),
    );

    if (getScreenType(tester) == DeviceScreenType.desktop) {
      Text numberText = tester.widget<Text>(find.descendant(
        of: trackRow,
        matching: find.byKey(const Key("numberText")),
      ));

      expect(
        numberText.data,
        equals("$pos"),
      );

      Text albumText = tester.widget<Text>(find.descendant(
        of: trackRow,
        matching: find.byKey(const Key("albumText")),
      ));

      expect(
        albumText.data,
        equals(track.album),
      );
    }
  }

  Future<void> playTrackAtPosition(int pos) async {
    await ensureTracksPage();

    final tracksList = find.byType(TracksList);

    expect(tracksList, findsOneWidget);

    final trackRow = find.descendant(
      of: tracksList,
      matching: find.byKey(Key("trackRow[$pos]")),
    );

    expect(trackRow, findsOneWidget);

    await tester.tap(trackRow);

    await tester.pumpAndSettle(const Duration(milliseconds: 10));
  }
}
