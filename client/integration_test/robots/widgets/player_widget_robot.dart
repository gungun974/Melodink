import 'package:flutter_test/flutter_test.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../helpers/get_screen_type.dart';
import 'desktop_player_widget_robot.dart';
import 'mobile_player_widget_robot.dart';

class PlayerWidgetRobot {
  final WidgetTester tester;

  late MobilePlayerWidgetRobot _mobile;
  late DesktopPlayerWidgetRobot _desktop;

  PlayerWidgetRobot({required this.tester}) {
    _mobile = MobilePlayerWidgetRobot(tester: tester);
    _desktop = DesktopPlayerWidgetRobot(tester: tester);
  }

  Future<void> playOrPausePlayer() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.playOrPausePlayer();
    }
    return _mobile.playOrPausePlayer();
  }

  Future<void> assertPlayerPause() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertPlayerPause();
    }
    return _mobile.assertPlayerPause();
  }

  Future<void> assertPlayerPlay() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertPlayerPlay();
    }
    return _mobile.assertPlayerPlay();
  }

  Future<void> assertPlayerDuration(String duration) async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertPlayerDuration(duration);
    }
    return _mobile.assertPlayerDuration(duration);
  }

  Future<void> assertCurrentTrack(Track track) async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertCurrentTrack(track);
    }
    return _mobile.assertCurrentTrack(track);
  }

  Future<void> skipToNext() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.skipToNext();
    }
    return _mobile.skipToNext();
  }

  Future<void> skipToPrevious() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.skipToPrevious();
    }
    return _mobile.skipToPrevious();
  }

  Future<void> tapRepeatButton() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.tapRepeatButton();
    }
    return _mobile.tapRepeatButton();
  }

  Future<void> assertRepeatOff() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertRepeatOff();
    }
    return _mobile.assertRepeatOff();
  }

  Future<void> assertRepeatAll() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertRepeatAll();
    }
    return _mobile.assertRepeatAll();
  }

  Future<void> assertRepeatOne() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertRepeatOne();
    }
    return _mobile.assertRepeatOne();
  }

  Future<void> tapShuffleButton() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.tapShuffleButton();
    }
    return _mobile.tapShuffleButton();
  }

  Future<void> assertShuffleOff() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertShuffleOff();
    }
    return _mobile.assertShuffleOff();
  }

  Future<void> assertShuffleOn() async {
    if (getScreenType(tester) == DeviceScreenType.desktop) {
      return _desktop.assertShuffleOn();
    }
    return _mobile.assertShuffleOn();
  }
}
