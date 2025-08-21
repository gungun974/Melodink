import 'package:flutter/foundation.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';

class SettingsViewModel extends ChangeNotifier {
  final AudioController audioController;

  SettingsViewModel({required this.audioController});

  AppSettings? state;

  String? _deviceId;

  Future<void> loadSettings() async {
    state = await SettingsRepository().getSettings();
    _deviceId = await SettingsRepository().getDeviceId();
    notifyListeners();
  }

  Future<void> setSettings(AppSettings newSettings) async {
    await SettingsRepository().setSettings(newSettings);

    state = await SettingsRepository().getSettings();
    _deviceId = await SettingsRepository().getDeviceId();
    notifyListeners();

    await audioController.updatePlayerQuality();
  }

  AppSettingTheme currentAppTheme() {
    final currentSettings = state;

    if (currentSettings == null) {
      return AppSettingTheme.base;
    }

    return currentSettings.theme;
  }

  bool shouldDynamicBackgroundColors() {
    final currentSettings = state;

    if (currentSettings == null) {
      return true;
    }

    return currentSettings.dynamicBackgroundColors;
  }

  AppSettingPlayerBarPosition currentPlayerBarPosition() {
    final currentSettings = state;

    if (currentSettings == null) {
      return AppSettingPlayerBarPosition.bottom;
    }

    return currentSettings.playerBarPosition;
  }

  AppSettingScoringSystem currentScoringSystem() {
    final currentSettings = state;

    if (currentSettings == null) {
      return AppSettingScoringSystem.none;
    }

    return currentSettings.scoringSystem;
  }

  String? deviceId() {
    return _deviceId;
  }

  bool isAutoScrollViewToCurrentTrackEnabled() {
    final currentSettings = state;

    if (currentSettings == null) {
      return false;
    }

    return currentSettings.autoScrollViewToCurrentTrack;
  }
}
