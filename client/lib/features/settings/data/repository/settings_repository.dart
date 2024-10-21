import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  Future<AppSettings> getSettings() async {
    final rawTheme = await asyncPrefs.getString("settingTheme");
    final rawPlayerBarPosition =
        await asyncPrefs.getString("settingPlayerBarPosition");

    AppSettingTheme? theme;
    AppSettingPlayerBarPosition? playerBarPosition;

    if (rawTheme != null) {
      theme = AppSettingTheme.values
          .where((value) => value.name == rawTheme)
          .firstOrNull;
    }

    if (rawPlayerBarPosition != null) {
      playerBarPosition = AppSettingPlayerBarPosition.values
          .where((value) => value.name == rawPlayerBarPosition)
          .firstOrNull;
    }

    final rememberLoopAndShuffleAcrossRestarts =
        await asyncPrefs.getBool("settingRememberLoopAndShuffleAcrossRestarts");
    final keepLastPlayingListAcrossRestarts =
        await asyncPrefs.getBool("settingKeepLastPlayingListAcrossRestarts");
    final autoScrollViewToCurrentTrack =
        await asyncPrefs.getBool("settingAutoScrollViewToCurrentTrack");
    final enableHistoryTracking =
        await asyncPrefs.getBool("settingEnableHistoryTracking");

    final shareAllHistoryTrackingToServer =
        await asyncPrefs.getBool("settingShareAllHistoryTrackingToServer");

    return AppSettings(
      theme: theme ?? AppSettingTheme.dynamic,
      playerBarPosition:
          playerBarPosition ?? AppSettingPlayerBarPosition.bottom,
      rememberLoopAndShuffleAcrossRestarts:
          rememberLoopAndShuffleAcrossRestarts ?? true,
      keepLastPlayingListAcrossRestarts:
          keepLastPlayingListAcrossRestarts ?? true,
      autoScrollViewToCurrentTrack: autoScrollViewToCurrentTrack ?? true,
      enableHistoryTracking: enableHistoryTracking ?? true,
      shareAllHistoryTrackingToServer: shareAllHistoryTrackingToServer ?? true,
    );
  }

  Future<void> setSettings(AppSettings settings) async {
    await asyncPrefs.setString(
      "settingTheme",
      settings.theme.name,
    );
    await asyncPrefs.setString(
      "settingPlayerBarPosition",
      settings.playerBarPosition.name,
    );

    await asyncPrefs.setBool(
      "settingRememberLoopAndShuffleAcrossRestarts",
      settings.rememberLoopAndShuffleAcrossRestarts,
    );

    await asyncPrefs.setBool(
      "settingKeepLastPlayingListAcrossRestarts",
      settings.keepLastPlayingListAcrossRestarts,
    );
    await asyncPrefs.setBool(
      "settingAutoScrollViewToCurrentTrack",
      settings.autoScrollViewToCurrentTrack,
    );
    await asyncPrefs.setBool(
      "settingEnableHistoryTracking",
      settings.enableHistoryTracking,
    );
    await asyncPrefs.setBool(
      "settingShareAllHistoryTrackingToServer",
      settings.shareAllHistoryTrackingToServer,
    );
  }
}

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(),
);
