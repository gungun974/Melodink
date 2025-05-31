import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/settings/domain/entities/equalizer.dart';

enum AppSettingTheme {
  base,
  dark,
  purple,
  cyan,
  grey,
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
  lossless,
}

enum AppSettingScoringSystem {
  none,
  like,
  stars,
}

class AppSettings extends Equatable {
  final AppSettingTheme theme;
  final bool dynamicBackgroundColors;
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

  final AppEqualizer equalizer;

  const AppSettings({
    required this.theme,
    required this.dynamicBackgroundColors,
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
    required this.equalizer,
  });

  AppSettings copyWith({
    AppSettingTheme? theme,
    bool? dynamicBackgroundColors,
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
    AppEqualizer? equalizer,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      dynamicBackgroundColors:
          dynamicBackgroundColors ?? this.dynamicBackgroundColors,
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
      equalizer: equalizer ?? this.equalizer,
    );
  }

  @override
  List<Object?> get props => [
        theme,
        dynamicBackgroundColors,
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
        equalizer,
      ];
}
