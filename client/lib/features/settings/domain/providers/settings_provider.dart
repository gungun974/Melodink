import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  late AudioController _audioController;

  @override
  Future<AppSettings> build() async {
    _audioController = ref.read(audioControllerProvider);

    return await SettingsRepository().getSettings();
  }

  setSettings(AppSettings newSettings) async {
    await SettingsRepository().setSettings(
      newSettings,
    );

    state = AsyncData(await SettingsRepository().getSettings());

    await _audioController.updatePlayerQuality();
  }
}

@riverpod
AppSettingTheme currentAppTheme(Ref ref) {
  final currentSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

  if (currentSettings == null) {
    return AppSettingTheme.base;
  }

  return currentSettings.theme;
}

@riverpod
bool shouldDynamicBackgroundColors(Ref ref) {
  final currentSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

  if (currentSettings == null) {
    return true;
  }

  return currentSettings.dynamicBackgroundColors;
}

@riverpod
AppSettingPlayerBarPosition currentPlayerBarPosition(Ref ref) {
  final currentSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

  if (currentSettings == null) {
    return AppSettingPlayerBarPosition.bottom;
  }

  return currentSettings.playerBarPosition;
}

@riverpod
AppSettingScoringSystem currentScoringSystem(Ref ref) {
  final currentSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

  if (currentSettings == null) {
    return AppSettingScoringSystem.none;
  }

  return currentSettings.scoringSystem;
}

@riverpod
Future<String> deviceId(Ref ref) {
  return SettingsRepository().getDeviceId();
}

@riverpod
bool isAutoScrollViewToCurrentTrackEnabled(Ref ref) {
  final currentSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

  if (currentSettings == null) {
    return false;
  }

  return currentSettings.autoScrollViewToCurrentTrack;
}
