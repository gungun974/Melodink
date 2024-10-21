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
}

class AppSettings extends Equatable {
  final AppSettingTheme theme;
  final AppSettingPlayerBarPosition playerBarPosition;

  final bool rememberLoopAndShuffleAcrossRestarts;
  final bool keepLastPlayingListAcrossRestarts;
  final bool autoScrollViewToCurrentTrack;

  final bool enableHistoryTracking;
  final bool shareAllHistoryTrackingToServer;

  const AppSettings({
    required this.theme,
    required this.playerBarPosition,
    required this.rememberLoopAndShuffleAcrossRestarts,
    required this.keepLastPlayingListAcrossRestarts,
    required this.autoScrollViewToCurrentTrack,
    required this.enableHistoryTracking,
    required this.shareAllHistoryTrackingToServer,
  });

  AppSettings copyWith({
    AppSettingTheme? theme,
    AppSettingPlayerBarPosition? playerBarPosition,
    bool? rememberLoopAndShuffleAcrossRestarts,
    bool? keepLastPlayingListAcrossRestarts,
    bool? autoScrollViewToCurrentTrack,
    bool? enableHistoryTracking,
    bool? shareAllHistoryTrackingToServer,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      playerBarPosition: playerBarPosition ?? this.playerBarPosition,
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
        rememberLoopAndShuffleAcrossRestarts,
        keepLastPlayingListAcrossRestarts,
        autoScrollViewToCurrentTrack,
        enableHistoryTracking,
        shareAllHistoryTrackingToServer,
      ];
}
