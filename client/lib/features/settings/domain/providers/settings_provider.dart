import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return await SettingsRepository().getSettings();
  }

  setSettings(AppSettings newSettings) async {
    await SettingsRepository().setSettings(
      newSettings,
    );

    state = AsyncData(await SettingsRepository().getSettings());
  }
}

@riverpod
AppSettingTheme currentAppTheme(
  CurrentAppThemeRef ref,
) {
  final currentSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

  if (currentSettings == null) {
    return AppSettingTheme.dynamic;
  }

  return currentSettings.theme;
}

@riverpod
AppSettingPlayerBarPosition currentPlayerBarPosition(
  CurrentPlayerBarPositionRef ref,
) {
  final currentSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

  if (currentSettings == null) {
    return AppSettingPlayerBarPosition.bottom;
  }

  return currentSettings.playerBarPosition;
}

@riverpod
Future<String> deviceId(
  DeviceIdRef ref,
) {
  return SettingsRepository().getDeviceId();
}

@riverpod
bool isAutoScrollViewToCurrentTrackEnabled(
  IsAutoScrollViewToCurrentTrackEnabledRef ref,
) {
  final currentSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

  if (currentSettings == null) {
    return false;
  }

  return currentSettings.autoScrollViewToCurrentTrack;
}
