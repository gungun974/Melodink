import 'package:equatable/equatable.dart';

enum AppSettingTheme {
  base,
  dark,
  dynamic,
}

enum AppSettingPlayerBarPosition {
  bottom,
  top,
  side,
  center,
}

enum AppSettingAudioQuality {
  low,
  medium,
  high,
  max,
  directFile,
}

enum AppSettingScoringSystem {
  none,
  like,
  stars,
}

class AppSettings extends Equatable {
  final AppSettingTheme theme;
  final AppSettingPlayerBarPosition playerBarPosition;
  final AppSettingScoringSystem scoringSystem;

  final AppSettingAudioQuality wifiAudioQuality;
  final AppSettingAudioQuality cellularAudioQuality;
  final AppSettingAudioQuality downloadAudioQuality;

  final bool rememberLoopAndShuffleAcrossRestarts;
  final bool keepLastPlayingListAcrossRestarts;
  final bool autoScrollViewToCurrentTrack;

  final bool enableHistoryTracking;
  final bool shareAllHistoryTrackingToServer;

  const AppSettings({
    required this.theme,
    required this.playerBarPosition,
    required this.scoringSystem,
    required this.wifiAudioQuality,
    required this.cellularAudioQuality,
    required this.downloadAudioQuality,
    required this.rememberLoopAndShuffleAcrossRestarts,
    required this.keepLastPlayingListAcrossRestarts,
    required this.autoScrollViewToCurrentTrack,
    required this.enableHistoryTracking,
    required this.shareAllHistoryTrackingToServer,
  });

  AppSettings copyWith({
    AppSettingTheme? theme,
    AppSettingPlayerBarPosition? playerBarPosition,
    AppSettingScoringSystem? scoringSystem,
    AppSettingAudioQuality? wifiAudioQuality,
    AppSettingAudioQuality? cellularAudioQuality,
    AppSettingAudioQuality? downloadAudioQuality,
    bool? rememberLoopAndShuffleAcrossRestarts,
    bool? keepLastPlayingListAcrossRestarts,
    bool? autoScrollViewToCurrentTrack,
    bool? enableHistoryTracking,
    bool? shareAllHistoryTrackingToServer,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      playerBarPosition: playerBarPosition ?? this.playerBarPosition,
      scoringSystem: scoringSystem ?? this.scoringSystem,
      wifiAudioQuality: wifiAudioQuality ?? this.wifiAudioQuality,
      cellularAudioQuality: cellularAudioQuality ?? this.cellularAudioQuality,
      downloadAudioQuality: downloadAudioQuality ?? this.downloadAudioQuality,
      rememberLoopAndShuffleAcrossRestarts:
          rememberLoopAndShuffleAcrossRestarts ??
              this.rememberLoopAndShuffleAcrossRestarts,
      keepLastPlayingListAcrossRestarts: keepLastPlayingListAcrossRestarts ??
          this.keepLastPlayingListAcrossRestarts,
      autoScrollViewToCurrentTrack:
          autoScrollViewToCurrentTrack ?? this.autoScrollViewToCurrentTrack,
      enableHistoryTracking:
          enableHistoryTracking ?? this.enableHistoryTracking,
      shareAllHistoryTrackingToServer: shareAllHistoryTrackingToServer ??
          this.shareAllHistoryTrackingToServer,
    );
  }

  @override
  List<Object?> get props => [
        theme,
        playerBarPosition,
        scoringSystem,
        wifiAudioQuality,
        cellularAudioQuality,
        downloadAudioQuality,
        rememberLoopAndShuffleAcrossRestarts,
        keepLastPlayingListAcrossRestarts,
        autoScrollViewToCurrentTrack,
        enableHistoryTracking,
        shareAllHistoryTrackingToServer,
      ];
}
