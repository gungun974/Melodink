import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/features/settings/domain/entities/equalizer.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SettingsRepository {
  SettingsRepository._privateConstructor();

  static final SettingsRepository _instance =
      SettingsRepository._privateConstructor();

  factory SettingsRepository() {
    return _instance;
  }

  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  Future<AppSettings> getSettings() async {
    final rawTheme = await asyncPrefs.getString("settingTheme");
    final rawPlayerBarPosition = await asyncPrefs.getString(
      "settingPlayerBarPosition",
    );
    final rawScoringSystem = await asyncPrefs.getString("settingScoringSystem");

    final rawWifiAudioQuality = await asyncPrefs.getString("wifiAudioQuality");
    final rawCellularAudioQuality = await asyncPrefs.getString(
      "cellularAudioQuality",
    );
    final rawDownloadAudioQuality = await asyncPrefs.getString(
      "downloadAudioQuality",
    );

    AppSettingTheme? theme;
    AppSettingPlayerBarPosition? playerBarPosition;
    AppSettingScoringSystem? scoringSystem;

    AppSettingAudioQuality? wifiAudioQuality;
    AppSettingAudioQuality? cellularAudioQuality;
    AppSettingAudioQuality? downloadAudioQuality;

    if (rawTheme != null) {
      theme = AppSettingTheme.values
          .where((value) => value.name == rawTheme)
          .firstOrNull;
    }

    final dynamicBackgroundColors = await asyncPrefs.getBool(
      "settingDynamicBackgroundColors",
    );

    if (rawPlayerBarPosition != null) {
      playerBarPosition = AppSettingPlayerBarPosition.values
          .where((value) => value.name == rawPlayerBarPosition)
          .firstOrNull;
    }

    if (rawScoringSystem != null) {
      scoringSystem = AppSettingScoringSystem.values
          .where((value) => value.name == rawScoringSystem)
          .firstOrNull;
    }

    if (rawWifiAudioQuality != null) {
      wifiAudioQuality = AppSettingAudioQuality.values
          .where((value) => value.name == rawWifiAudioQuality)
          .firstOrNull;
    }

    if (rawCellularAudioQuality != null) {
      cellularAudioQuality = AppSettingAudioQuality.values
          .where((value) => value.name == rawCellularAudioQuality)
          .firstOrNull;
    }

    if (rawDownloadAudioQuality != null) {
      downloadAudioQuality = AppSettingAudioQuality.values
          .where((value) => value.name == rawDownloadAudioQuality)
          .firstOrNull;
    }

    final rememberLoopAndShuffleAcrossRestarts = await asyncPrefs.getBool(
      "settingRememberLoopAndShuffleAcrossRestarts",
    );
    final keepLastPlayingListAcrossRestarts = await asyncPrefs.getBool(
      "settingKeepLastPlayingListAcrossRestarts",
    );
    final autoScrollViewToCurrentTrack = await asyncPrefs.getBool(
      "settingAutoScrollViewToCurrentTrack",
    );
    final enableHistoryTracking = await asyncPrefs.getBool(
      "settingEnableHistoryTracking",
    );

    final shareAllHistoryTrackingToServer = await asyncPrefs.getBool(
      "settingShareAllHistoryTrackingToServer",
    );

    final showTrackRemainingDuration = await asyncPrefs.getBool(
      "showTrackRemainingDuration",
    );

    return AppSettings(
      theme: theme ?? AppSettingTheme.base,
      dynamicBackgroundColors: dynamicBackgroundColors ?? true,
      playerBarPosition:
          playerBarPosition ?? AppSettingPlayerBarPosition.bottom,
      scoringSystem: scoringSystem ?? AppSettingScoringSystem.like,
      wifiAudioQuality: wifiAudioQuality ?? AppSettingAudioQuality.lossless,
      cellularAudioQuality: cellularAudioQuality ?? AppSettingAudioQuality.low,
      downloadAudioQuality:
          downloadAudioQuality ??
          (!kIsWeb && (Platform.isIOS || Platform.isAndroid)
              ? AppSettingAudioQuality.medium
              : AppSettingAudioQuality.lossless),
      rememberLoopAndShuffleAcrossRestarts:
          rememberLoopAndShuffleAcrossRestarts ?? true,
      keepLastPlayingListAcrossRestarts:
          keepLastPlayingListAcrossRestarts ?? true,
      autoScrollViewToCurrentTrack: autoScrollViewToCurrentTrack ?? true,
      enableHistoryTracking: enableHistoryTracking ?? true,
      shareAllHistoryTrackingToServer: shareAllHistoryTrackingToServer ?? true,
      showTrackRemainingDuration: showTrackRemainingDuration ?? false,
      equalizer: await getEqualizer(),
    );
  }

  Future<void> setSettings(AppSettings settings) async {
    await asyncPrefs.setString("settingTheme", settings.theme.name);

    await asyncPrefs.setBool(
      "settingDynamicBackgroundColors",
      settings.dynamicBackgroundColors,
    );

    await asyncPrefs.setString(
      "settingPlayerBarPosition",
      settings.playerBarPosition.name,
    );
    await asyncPrefs.setString(
      "settingScoringSystem",
      settings.scoringSystem.name,
    );

    await asyncPrefs.setString(
      "wifiAudioQuality",
      settings.wifiAudioQuality.name,
    );
    await asyncPrefs.setString(
      "cellularAudioQuality",
      settings.cellularAudioQuality.name,
    );
    await asyncPrefs.setString(
      "downloadAudioQuality",
      settings.downloadAudioQuality.name,
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

    await asyncPrefs.setBool(
      "showTrackRemainingDuration",
      settings.showTrackRemainingDuration,
    );

    await saveEqualizer(settings.equalizer);
  }

  Future<void> saveEqualizer(AppEqualizer equalizer) async {
    await asyncPrefs.setBool('equalizer', equalizer.enabled);

    await asyncPrefs.setString(
      'equalizerBands',
      jsonEncode(
        equalizer.bands.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  Future<AppEqualizer> getEqualizer() async {
    try {
      final enabled = await asyncPrefs.getBool('equalizer') ?? false;

      final jsonString = await asyncPrefs.getString('equalizerBands');
      if (jsonString == null) {
        return AppEqualizer(enabled: enabled, bands: {});
      }

      return AppEqualizer(
        enabled: enabled,
        bands: (jsonDecode(jsonString) as Map<String, dynamic>).map(
          (key, value) =>
              MapEntry(double.parse(key), (value as num).toDouble()),
        ),
      );
    } catch (e) {
      return AppEqualizer(enabled: false, bands: {});
    }
  }

  Future<String> getDeviceId() async {
    final deviceId = await getConfigString("DEVICE_ID");

    if (deviceId != null) {
      return deviceId;
    }

    const uuid = Uuid();

    final newDeviceId = uuid.v4();

    await setConfigString("DEVICE_ID", newDeviceId);

    return newDeviceId;
  }

  Future<void> setConfigString(String key, String value) async {
    final db = await DatabaseService.getDatabase();

    db.execute(
      """
       INSERT OR REPLACE INTO config (key, value)
       VALUES (?, ?);
    """,
      [key, value],
    );
  }

  Future<String?> getConfigString(String key) async {
    final db = await DatabaseService.getDatabase();

    final result = db.select(
      """
       SELECT value FROM config WHERE key = ?;
    """,
      [key],
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first["value"] as String;
  }
}
