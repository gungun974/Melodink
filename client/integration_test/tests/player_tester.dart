import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodink_client/core/error/failures.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_shuffler.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:melodink_client/features/tracks/domain/entities/track_file.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:melodink_client/main.dart' as app;
import 'package:mocktail/mocktail.dart';

import '../../test/helpers/generate_array.dart';
import '../../test/unit/features/tracks/domain/entities/track.dart';
import '../helpers/async_wait.dart';
import '../robots/pages/all_tracks_page_robot.dart';
import '../robots/widgets/desktop_player_widget_robot.dart';
import '../robots/widgets/mobile_player_widget_robot.dart';
import '../robots/widgets/player_widget_robot.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

class MockTrackShuffler extends Mock implements TrackShuffler {}

void playerTests() {
  late MockTrackRepository trackRepository;

  late MockTrackShuffler trackShuffler;

  setUp(() {
    trackRepository = MockTrackRepository();

    trackShuffler = MockTrackShuffler();

    if (sl.isRegistered<TrackRepository>()) {
      sl.unregister<TrackRepository>();
    }

    sl.registerLazySingleton<TrackRepository>(
      () => trackRepository,
    );

    if (sl.isRegistered<TrackShuffler>()) {
      sl.unregister<TrackShuffler>();
    }

    sl.registerLazySingleton<TrackShuffler>(
      () => trackShuffler,
    );
  });

  final sample1 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/sample1.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final sample2 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/sample2.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final sample3 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/sample3.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final sample4 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/sample4.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final sample5 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/sample5.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final shortSample1 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/short_sample1.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final shortSample2 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/short_sample2.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final shortSample3 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/short_sample3.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final shortSample4 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/short_sample4.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  final shortSample5 = TrackFile(
    uri: Uri.parse("asset:///integration_test/assets/short_sample5.mp3"),
    image: Uri.parse("asset:///assets/melodink_icon.png"),
    format: AudioStreamFormat.file,
    quality: AudioStreamQuality.low,
  );

  group('basic playback', () {
    testWidgets('should play the track', (tester) async {
      // Arrange
      final track = getRandomTrack().copyWith(
        cacheFile: sample1,
        duration: const Duration(seconds: 5),
      );

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok([
          track,
        ]),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      // Play

      await allTracksPageRobot.playTrackAtPosition(1);

      await playerWidgetRobot.assertPlayerPlay();

      await playerWidgetRobot.assertCurrentTrack(track);

      await playerWidgetRobot.assertPlayerDuration("0:01");

      await playerWidgetRobot.assertPlayerPlay();

      await wait(4900);

      await playerWidgetRobot.assertPlayerDuration("0:05");

      await playerWidgetRobot.assertPlayerPause();

      await wait(1100);

      await playerWidgetRobot.assertPlayerDuration("0:05");
    });

    testWidgets('should play tracks continuously', (tester) async {
      // Arrange
      final track1 = getRandomTrack().copyWith(
        cacheFile: sample1,
        duration: const Duration(seconds: 5),
      );
      final track2 = getRandomTrack().copyWith(
        cacheFile: sample2,
        duration: const Duration(seconds: 5),
      );
      final track3 = getRandomTrack().copyWith(
        cacheFile: sample3,
        duration: const Duration(seconds: 5),
      );

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok([
          track1,
          track2,
          track3,
        ]),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      // Play

      await allTracksPageRobot.playTrackAtPosition(1);

      await playerWidgetRobot.assertPlayerPlay();

      await playerWidgetRobot.assertCurrentTrack(track1);

      await playerWidgetRobot.assertPlayerDuration("0:01");

      await playerWidgetRobot.assertPlayerPlay();

      await wait(3900);

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPlay();

      await playerWidgetRobot.assertCurrentTrack(track2);

      await wait(4900);

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPlay();

      await playerWidgetRobot.assertCurrentTrack(track3);

      await wait(4900);

      await playerWidgetRobot.assertPlayerDuration("0:05");

      await playerWidgetRobot.assertPlayerPause();

      await wait(1100);

      await playerWidgetRobot.assertPlayerDuration("0:05");
    });

    testWidgets('should play 30 tracks in order', (tester) async {
      // Arrange

      int i = 0;

      final tracks = generateArray(() {
        return getRandomTrack().copyWith(
          cacheFile: [
            shortSample1,
            shortSample2,
            shortSample3,
            shortSample4,
            shortSample5,
          ][(i++) % 5],
          duration: const Duration(seconds: 1),
        );
      }, 30);

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok(tracks),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      AudioHandler audioHandler = sl();

      await audioHandler.setSpeed(0.5);

      await wait(100);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      // Play

      await allTracksPageRobot.playTrackAtPosition(1);

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);

      await audioHandler.setSpeed(4.5);

      for (int i = 0; i < 30; i++) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }
    });

    testWidgets('should fast skip back to back 30 tracks in order',
        (tester) async {
      // Arrange

      int i = 0;

      final tracks = generateArray(() {
        return getRandomTrack().copyWith(
          cacheFile: [
            sample1,
            sample2,
            sample3,
            sample4,
            sample5,
          ][(i++) % 5],
          duration: const Duration(seconds: 5),
        );
      }, 30);

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok(tracks),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      AudioHandler audioHandler = sl();

      await audioHandler.setSpeed(0.5);

      await wait(100);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      // Play

      await allTracksPageRobot.playTrackAtPosition(1);

      for (int i = 0; i < 29; i++) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToNext();
      }

      for (int i = 29; i > 0; i--) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToPrevious();
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);
    });
  });

  group('repeat playback', () {
    testWidgets('verify repeat all tracks works as expected', (tester) async {
      // Arrange

      int i = 0;

      final tracks = generateArray(() {
        return getRandomTrack().copyWith(
          cacheFile: [
            sample1,
            sample2,
            sample3,
            sample4,
            sample5,
          ][(i++) % 5],
          duration: const Duration(seconds: 5),
        );
      }, 5);

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok(tracks),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      AudioHandler audioHandler = sl();

      await audioHandler.setSpeed(0.5);

      await wait(100);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      // Check default state

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      await playerWidgetRobot.assertRepeatOff();

      // Enable Repeat

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatAll();

      // Play

      await allTracksPageRobot.playTrackAtPosition(2);

      for (int i = 1; i < 5; i++) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToNext();
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[1]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[2]);

      // Disable Repeat

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatOff();

      // Play

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[3]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[4]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[4]);

      // Verify loop one dont mess with previous and next history

      for (int i = 3; i >= 0; i--) {
        await playerWidgetRobot.skipToPrevious();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      for (int i = 0; i < 4; i++) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToNext();
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[4]);

      // Verify after loop jump, you cant go back

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatAll();

      await playerWidgetRobot.assertCurrentTrack(tracks[4]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);

      await playerWidgetRobot.skipToPrevious();

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);
    });

    testWidgets('verify repeat one track works as expected', (tester) async {
      // Arrange

      int i = 0;

      final tracks = generateArray(() {
        return getRandomTrack().copyWith(
          cacheFile: [
            sample1,
            sample2,
            sample3,
            sample4,
            sample5,
          ][(i++) % 5],
          duration: const Duration(seconds: 5),
        );
      }, 5);

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok(tracks),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      AudioHandler audioHandler = sl();

      await audioHandler.setSpeed(0.5);

      await wait(100);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      // Check default state

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      await playerWidgetRobot.assertRepeatOff();

      // Enable Repeat

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatOne();

      // Play

      await allTracksPageRobot.playTrackAtPosition(3);

      for (int i = 0; i < 5; i++) {
        await playerWidgetRobot.assertCurrentTrack(tracks[2]);

        await playerWidgetRobot.skipToNext();
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[2]);

      // Disable Repeat

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatOff();

      // Play

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[3]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[4]);

      // Verify loop one dont mess with previous and next history

      for (int i = 3; i >= 0; i--) {
        await playerWidgetRobot.skipToPrevious();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      for (int i = 0; i > 5; i--) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToNext();
      }
    });
  });

  group('random playback', () {
    testWidgets('should verify shuffle works as expected', (tester) async {
      // Arrange

      int i = 0;

      final tracks = generateArray(() {
        return getRandomTrack().copyWith(
          cacheFile: [
            sample1,
            sample2,
            sample3,
            sample4,
            sample5,
          ][(i++) % 5],
          duration: const Duration(seconds: 5),
        );
      }, 30);

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok(tracks),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      AudioHandler audioHandler = sl();

      await audioHandler.setSpeed(0.5);

      await wait(100);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      // Check default state

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      await playerWidgetRobot.assertShuffleOff();

      // Normal Play

      await allTracksPageRobot.playTrackAtPosition(1);

      for (int i = 0; i < 5; i++) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToNext();
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[5]);

      // Enable Random

      final randomTracksOrder = [
        7,
        28,
        1,
        23,
        26,
        8,
        21,
        9,
        18,
        25,
        12,
        0,
        16,
        20,
        4,
        17,
        15,
        29,
        10,
        6,
        27,
        19,
        2,
        11,
        22,
        3,
        13,
        24,
        14,
      ];

      when(() => trackShuffler.shuffle(any())).thenAnswer((arguments) {
        final nextTracks =
            arguments.positionalArguments[0] as List<IndexedTrack>;

        IndexedTrack findIndexTrackByTrack(Track track) {
          return nextTracks.firstWhere((element) => element.track == track);
        }

        return randomTracksOrder
            .map((i) => findIndexTrackByTrack(tracks[i]))
            .toList();
      });

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOn();

      // Random play

      await playerWidgetRobot.assertCurrentTrack(tracks[5]);

      for (var i in randomTracksOrder) {
        await playerWidgetRobot.skipToNext();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      for (var i in randomTracksOrder.reversed) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToPrevious();
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[5]);

      // Do a loop

      await playerWidgetRobot.assertRepeatOff();

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatAll();

      for (var i in randomTracksOrder) {
        await playerWidgetRobot.skipToNext();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[5]);

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatOff();

      // Break the shuffle at track 4

      for (var i in randomTracksOrder) {
        await playerWidgetRobot.skipToNext();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        if (i == 4) {
          break;
        }
      }

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOff();

      await playerWidgetRobot.assertCurrentTrack(tracks[4]);

      for (int i = 5; i <= 29; i++) {
        await playerWidgetRobot.skipToNext();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      for (int i = 28; i >= 0; i--) {
        await playerWidgetRobot.skipToPrevious();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);
    });

    testWidgets('shuffle should not go crazy on foreign track of the playlist',
        (tester) async {
      // Arrange

      int i = 0;

      final tracks = generateArray(() {
        return getRandomTrack().copyWith(
          cacheFile: [
            sample1,
            sample2,
            sample3,
            sample4,
            sample5,
          ][(i++) % 5],
          duration: const Duration(seconds: 5),
        );
      }, 5);

      final foreignTrack = getRandomTrack().copyWith(
        cacheFile: sample3,
        duration: const Duration(seconds: 5),
      );

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok(tracks),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      PlayerCubit playerCubit = sl();

      AudioHandler audioHandler = sl();

      await audioHandler.setSpeed(0.5);

      await wait(100);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      // Check default state

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      await playerWidgetRobot.assertShuffleOff();

      // Normal Play

      await allTracksPageRobot.playTrackAtPosition(1);

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);

      // Introduce foreign track to playlist from queue

      playerCubit.addTrackToQueue(foreignTrack);

      await wait(100);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(foreignTrack);

      // Enable Random

      final randomTracksOrder = [
        3,
        1,
        0,
        2,
        4,
      ];

      when(() => trackShuffler.shuffle(any())).thenAnswer((arguments) {
        final nextTracks =
            arguments.positionalArguments[0] as List<IndexedTrack>;

        IndexedTrack findIndexTrackByTrack(Track track) {
          return nextTracks.firstWhere((element) => element.track == track);
        }

        return randomTracksOrder
            .map((i) => findIndexTrackByTrack(tracks[i]))
            .toList();
      });

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOn();

      // Random play

      await playerWidgetRobot.assertCurrentTrack(foreignTrack);

      for (var i in randomTracksOrder) {
        await playerWidgetRobot.skipToNext();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      for (var i in randomTracksOrder.reversed) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToPrevious();
      }

      await playerWidgetRobot.assertCurrentTrack(foreignTrack);

      // Disable shuffle

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOff();

      await playerWidgetRobot.assertCurrentTrack(foreignTrack);

      for (int i = 0; i <= 4; i++) {
        await playerWidgetRobot.skipToNext();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      for (int i = 3; i >= 0; i--) {
        await playerWidgetRobot.skipToPrevious();

        await playerWidgetRobot.assertCurrentTrack(tracks[i]);
      }

      await playerWidgetRobot.skipToPrevious();

      await playerWidgetRobot.assertCurrentTrack(foreignTrack);
    });
  });

  group('queue playback', () {
    testWidgets('should verify queue works as expected', (tester) async {
      // Arrange

      int i = 0;

      final tracks = generateArray(() {
        return getRandomTrack().copyWith(
          cacheFile: [
            sample1,
            sample2,
            sample3,
            sample4,
            sample5,
          ][(i++) % 5],
          duration: const Duration(seconds: 5),
        );
      }, 5);

      final extraTracks = generateArray(() {
        return getRandomTrack().copyWith(
          cacheFile: [
            sample1,
            sample2,
            sample3,
            sample4,
            sample5,
          ][(i++) % 5],
          duration: const Duration(seconds: 5),
        );
      }, 5);

      when(trackRepository.getAllTracks).thenAnswer(
        (_) async => Ok(tracks),
      );

      final allTracksPageRobot = AllTracksPageRobot(tester: tester);

      final playerWidgetRobot = PlayerWidgetRobot(tester: tester);

      PlayerCubit playerCubit = sl();

      AudioHandler audioHandler = sl();

      await audioHandler.setSpeed(0.5);

      await wait(100);

      // Act / Assert
      await tester.pumpWidget(const app.MyApp());

      await allTracksPageRobot.goto();

      await allTracksPageRobot.assertCurrentPage();

      // Check default state

      await playerWidgetRobot.assertPlayerDuration("0:00");

      await playerWidgetRobot.assertPlayerPause();

      await playerWidgetRobot.assertShuffleOff();

      // Normal Play

      await allTracksPageRobot.playTrackAtPosition(1);

      for (int i = 0; i < 3; i++) {
        await playerWidgetRobot.assertCurrentTrack(tracks[i]);

        await playerWidgetRobot.skipToNext();
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[3]);

      // Fill the queue

      playerCubit.addTrackToQueue(extraTracks[0]);

      playerCubit.addTrackToQueue(extraTracks[1]);

      playerCubit.addTrackToQueue(extraTracks[2]);

      await wait(100);

      // Explore the queue

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[0]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[1]);

      // Add extra thing while been in queue zone

      playerCubit.addTrackToQueue(extraTracks[2]);

      playerCubit.addTrackToQueue(extraTracks[3]);

      await wait(100);

      // Explore the queue part II

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[2]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[2]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[3]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[4]);

      // Verify new tracks previous and next order

      final newTracksWithQueue = [
        tracks[0],
        tracks[1],
        tracks[2],
        tracks[3],
        extraTracks[0],
        extraTracks[1],
        extraTracks[2],
        extraTracks[2],
        extraTracks[3],
        tracks[4],
      ];

      for (var i in newTracksWithQueue.reversed) {
        await playerWidgetRobot.assertCurrentTrack(i);

        await playerWidgetRobot.skipToPrevious();
      }

      for (var i in newTracksWithQueue) {
        await playerWidgetRobot.assertCurrentTrack(i);

        await playerWidgetRobot.skipToNext();
      }

      await playerWidgetRobot.assertCurrentTrack(tracks[4]);

      // Verify queue is not clear on playlist load

      playerCubit.addTrackToQueue(extraTracks[4]);

      playerCubit.addTrackToQueue(extraTracks[1]);

      await wait(100);

      await allTracksPageRobot.playTrackAtPosition(1);

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[4]);

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[1]);

      // Verify loop one don't mess with queue order

      await allTracksPageRobot.playTrackAtPosition(1);

      await wait(100);

      playerCubit.addTrackToQueue(extraTracks[2]);

      playerCubit.addTrackToQueue(extraTracks[0]);

      await wait(100);

      await playerWidgetRobot.assertRepeatOff();

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);

      await playerWidgetRobot.tapRepeatButton();
      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatOne();

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatOff();

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[2]);

      await playerWidgetRobot.tapRepeatButton();
      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatOne();
      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[2]);

      await playerWidgetRobot.tapRepeatButton();

      await playerWidgetRobot.assertRepeatOff();

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[0]);

      // Verify shuffle and unshuflle don't mess with queue order

      await allTracksPageRobot.playTrackAtPosition(1);

      await wait(100);

      playerCubit.addTrackToQueue(extraTracks[3]);

      playerCubit.addTrackToQueue(extraTracks[1]);

      await wait(100);

      await playerWidgetRobot.assertShuffleOff();

      await playerWidgetRobot.assertCurrentTrack(tracks[0]);

      final randomTracksOrder = [
        2,
        3,
        4,
        1,
      ];

      when(() => trackShuffler.shuffle(any())).thenAnswer((arguments) {
        final nextTracks =
            arguments.positionalArguments[0] as List<IndexedTrack>;

        IndexedTrack findIndexTrackByTrack(Track track) {
          return nextTracks.firstWhere((element) => element.track == track);
        }

        return randomTracksOrder
            .map((i) => findIndexTrackByTrack(tracks[i]))
            .toList();
      });

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOn();

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOff();

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOn();

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[3]);

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOff();

      randomTracksOrder.add(0);

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOn();

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOff();

      await playerWidgetRobot.tapShuffleButton();

      await playerWidgetRobot.assertShuffleOn();

      await playerWidgetRobot.skipToNext();

      await playerWidgetRobot.assertCurrentTrack(extraTracks[1]);
    });
  });
}
