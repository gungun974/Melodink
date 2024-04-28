import 'package:flutter_test/flutter_test.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:melodink_client/main.dart' as app;
import 'package:mocktail/mocktail.dart';

import '../../test/unit/features/tracks/domain/entities/track.dart';
import '../robots/pages/all_tracks_page_robot.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void allTracksListTests() {
  late MockTrackRepository trackRepository;

  setUp(() {
    trackRepository = MockTrackRepository();

    if (sl.isRegistered<TrackRepository>()) {
      sl.unregister<TrackRepository>();
    }

    sl.registerLazySingleton<TrackRepository>(
      () => trackRepository,
    );
  });

  testWidgets('should display zero track', (tester) async {
    // Arrange
    when(trackRepository.getAllTracks).thenAnswer(
      (_) async => const Ok([]),
    );

    // Act / Assert
    await tester.pumpWidget(const app.MyApp());

    final allTracksPageRobot = AllTracksPageRobot(tester: tester);

    await allTracksPageRobot.goto();

    await allTracksPageRobot.assertCurrentPage();

    await allTracksPageRobot.assertPlaylistNumberOfTracks(0);
  });

  testWidgets('should display one track', (tester) async {
    // Arrange
    Track track = getRandomTrack();

    when(trackRepository.getAllTracks).thenAnswer(
      (_) async => Ok([
        track,
      ]),
    );

    // Act / Assert
    await tester.pumpWidget(const app.MyApp());

    final allTracksPageRobot = AllTracksPageRobot(tester: tester);

    await allTracksPageRobot.goto();

    await allTracksPageRobot.assertCurrentPage();

    await allTracksPageRobot.assertPlaylistNumberOfTracks(1);

    await allTracksPageRobot.assertTrackPresentAtPosition(track, 1);
  });

  testWidgets('should display multipe tracks', (tester) async {
    // Arrange
    Track track1 = getRandomTrack();
    Track track2 = getRandomTrack();
    Track track3 = getRandomTrack();

    when(trackRepository.getAllTracks).thenAnswer(
      (_) async => Ok([
        track1,
        track2,
        track3,
      ]),
    );

    // Act / Assert
    await tester.pumpWidget(const app.MyApp());

    final allTracksPageRobot = AllTracksPageRobot(tester: tester);

    await allTracksPageRobot.goto();

    await allTracksPageRobot.assertCurrentPage();

    await allTracksPageRobot.assertPlaylistNumberOfTracks(3);

    await allTracksPageRobot.assertTrackPresentAtPosition(track1, 1);
    await allTracksPageRobot.assertTrackPresentAtPosition(track2, 2);
    await allTracksPageRobot.assertTrackPresentAtPosition(track3, 3);
  });
}
