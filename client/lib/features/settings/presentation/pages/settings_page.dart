import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/settings/presentation/widgets/server_info.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_button_option.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_dropdown_option.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_equalizer.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_pannel.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_toggle_option.dart';
import 'package:melodink_client/features/sync/data/repository/sync_repository.dart';
import 'package:melodink_client/features/track/domain/manager/download_manager.dart';
import 'package:melodink_client/features/track/presentation/modals/import_tracks_modal.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final forceOffline = context.select<NetworkInfo, bool>(
      (networkInfo) => networkInfo.getForceOffline(),
    );

    final isServerReachable = context.select<NetworkInfo, bool>(
      (networkInfo) => networkInfo.isServerRecheable(),
    );

    return Stack(
      children: [
        AppNavigationHeader(
          alwayShow: true,
          title: Text(t.general.settings),
          child: AppScreenTypeLayoutBuilder(
            builder: (context, size) {
              final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

              return SingleChildScrollView(
                child: MaxContainer(
                  maxWidth: 512,
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Consumer<SettingsViewModel>(
                    builder: (context, viewModel, _) {
                      final settings = viewModel.state;
                      if (settings == null) {
                        return SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: padding),
                          const ServerInfo(),
                          const SizedBox(height: 16),
                          SettingPannel(
                            title: t.general.tracks,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      text: t.actions.importTracks,
                                      type: AppButtonType.primary,
                                      onPressed: () {
                                        if (!NetworkInfo()
                                            .isServerRecheable()) {
                                          AppNotificationManager.of(
                                            context,
                                          ).notify(
                                            context,
                                            title:
                                                t.notifications.offline.title,
                                            message:
                                                t.notifications.offline.message,
                                            type: AppNotificationType.danger,
                                          );
                                          return;
                                        }

                                        ImportTracksModal.showModal(context);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                          SettingPannel(
                            title: t.general.network,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (!forceOffline)
                                    Expanded(
                                      child: AppButton(
                                        text: t.actions.forceOffline,
                                        type: AppButtonType.primary,
                                        onPressed: () async {
                                          context
                                              .read<NetworkInfo>()
                                              .setForceOffline(true);
                                        },
                                      ),
                                    ),
                                  if (forceOffline)
                                    Expanded(
                                      child: AppButton(
                                        text: t.actions.disableForceOffline,
                                        type: AppButtonType.primary,
                                        onPressed: () async {
                                          context
                                              .read<NetworkInfo>()
                                              .setForceOffline(false);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      text: t.actions.performFullSync,
                                      type: AppButtonType.primary,
                                      onPressed: !isServerReachable
                                          ? null
                                          : () async {
                                              AppNotificationManager.of(
                                                context,
                                              ).notify(
                                                context,
                                                message: t
                                                    .notifications
                                                    .syncStarted
                                                    .message,
                                                type: AppNotificationType.info,
                                              );

                                              try {
                                                final syncRepository = context
                                                    .read<SyncRepository>();

                                                await syncRepository
                                                    .performSync(
                                                      fullSync: true,
                                                    );
                                                await syncRepository
                                                    .syncPlayedTracks();

                                                if (!context.mounted) {
                                                  return;
                                                }

                                                AppNotificationManager.of(
                                                  context,
                                                ).notify(
                                                  context,
                                                  message: t
                                                      .notifications
                                                      .syncEnded
                                                      .message,
                                                  type:
                                                      AppNotificationType.info,
                                                );
                                              } catch (_) {
                                                if (!context.mounted) {
                                                  return;
                                                }

                                                AppNotificationManager.of(
                                                  context,
                                                ).notify(
                                                  context,
                                                  title: t
                                                      .notifications
                                                      .somethingWentWrong
                                                      .title,
                                                  message: t
                                                      .notifications
                                                      .syncEnded
                                                      .message,
                                                  type: AppNotificationType
                                                      .danger,
                                                );
                                              }
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SettingPannel(
                            title: t.general.appearance,
                            children: [
                              SettingDropdownOption(
                                text: "${t.general.theme} :",
                                value: settings.theme,
                                onChanged: (theme) => viewModel.setSettings(
                                  settings.copyWith(theme: theme),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: AppSettingTheme.base,
                                    child: Text(t.themes.kDefault),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingTheme.dark,
                                    child: Text(t.themes.dark),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingTheme.purple,
                                    child: Text(t.themes.purple),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingTheme.cyan,
                                    child: Text(t.themes.cyan),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingTheme.grey,
                                    child: Text(t.themes.grey),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              SettingToggleOption(
                                text: "${t.settings.dynamicBackgroundColors} :",
                                value: settings.dynamicBackgroundColors,
                                onToggle: (value) => viewModel.setSettings(
                                  settings.copyWith(
                                    dynamicBackgroundColors: value,
                                  ),
                                ),
                              ),
                              const Divider(height: 24),
                              if (size == AppScreenTypeLayout.desktop)
                                SettingDropdownOption(
                                  text:
                                      "${t.settings.desktopPlayerBarPosition} :",
                                  value: settings.playerBarPosition,
                                  onChanged: (position) =>
                                      viewModel.setSettings(
                                        settings.copyWith(
                                          playerBarPosition: position,
                                        ),
                                      ),
                                  items: [
                                    DropdownMenuItem(
                                      value: AppSettingPlayerBarPosition.bottom,
                                      child: Text(t.positions.bottom),
                                    ),
                                    DropdownMenuItem(
                                      value: AppSettingPlayerBarPosition.top,
                                      child: Text(t.positions.top),
                                    ),
                                    DropdownMenuItem(
                                      value: AppSettingPlayerBarPosition.side,
                                      child: Text(t.positions.side),
                                    ),
                                    DropdownMenuItem(
                                      value: AppSettingPlayerBarPosition.center,
                                      child: Text(t.positions.center),
                                    ),
                                  ],
                                ),
                              if (size == AppScreenTypeLayout.desktop)
                                const Divider(height: 24),
                              SettingDropdownOption(
                                text: "${t.settings.scoringSystem} :",
                                value: settings.scoringSystem,
                                onChanged: (scoringSystem) =>
                                    viewModel.setSettings(
                                      settings.copyWith(
                                        scoringSystem: scoringSystem,
                                      ),
                                    ),
                                items: [
                                  DropdownMenuItem(
                                    value: AppSettingScoringSystem.none,
                                    child: Text(t.scoringSystem.none),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingScoringSystem.like,
                                    child: Text(t.scoringSystem.like),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingScoringSystem.stars,
                                    child: Text(t.scoringSystem.stars),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SettingPannel(
                            title: t.general.audioQuality,
                            children: [
                              SettingDropdownOption(
                                text: "${t.general.wifiStreaming} :",
                                value: settings.wifiAudioQuality,
                                onChanged: (audioQuality) =>
                                    viewModel.setSettings(
                                      settings.copyWith(
                                        wifiAudioQuality: audioQuality,
                                      ),
                                    ),
                                items: [
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.low,
                                    child: Text(t.audioQualities.low),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.medium,
                                    child: Text(t.audioQualities.medium),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.high,
                                    child: Text(t.audioQualities.high),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.lossless,
                                    child: Text(t.audioQualities.lossless),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              SettingDropdownOption(
                                text: "${t.general.cellularStreaming} :",
                                value: settings.cellularAudioQuality,
                                onChanged: (audioQuality) =>
                                    viewModel.setSettings(
                                      settings.copyWith(
                                        cellularAudioQuality: audioQuality,
                                      ),
                                    ),
                                items: [
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.low,
                                    child: Text(t.audioQualities.low),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.medium,
                                    child: Text(t.audioQualities.medium),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.high,
                                    child: Text(t.audioQualities.high),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.lossless,
                                    child: Text(t.audioQualities.lossless),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              SettingDropdownOption(
                                text: "${t.general.downloadQuality} :",
                                value: settings.downloadAudioQuality,
                                onChanged: (audioQuality) =>
                                    viewModel.setSettings(
                                      settings.copyWith(
                                        downloadAudioQuality: audioQuality,
                                      ),
                                    ),
                                items: [
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.low,
                                    child: Text(t.audioQualities.low),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.medium,
                                    child: Text(t.audioQualities.medium),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.high,
                                    child: Text(t.audioQualities.high),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSettingAudioQuality.lossless,
                                    child: Text(t.audioQualities.lossless),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SettingEqualizer(),
                          const SizedBox(height: 16),
                          SettingPannel(
                            title: t.general.playing,
                            children: [
                              SettingToggleOption(
                                text:
                                    "${t.settings.rememberLoopAndShuffleAcrossRestarts} :",
                                value: settings
                                    .rememberLoopAndShuffleAcrossRestarts,
                                onToggle: (value) => viewModel.setSettings(
                                  settings.copyWith(
                                    rememberLoopAndShuffleAcrossRestarts: value,
                                  ),
                                ),
                              ),
                              const Divider(height: 24),
                              SettingToggleOption(
                                text:
                                    "${t.settings.autoScrollViewToCurrentTrack} :",
                                value: settings.autoScrollViewToCurrentTrack,
                                onToggle: (value) => viewModel.setSettings(
                                  settings.copyWith(
                                    autoScrollViewToCurrentTrack: value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SettingPannel(
                            title: t.general.tracking,
                            children: [
                              SettingToggleOption(
                                text:
                                    "${t.settings.shareAllHistoryTrackingToServer} :",
                                value: settings.shareAllHistoryTrackingToServer,
                                onToggle: (value) => viewModel.setSettings(
                                  settings.copyWith(
                                    shareAllHistoryTrackingToServer: value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SettingPannel(
                            title: t.general.download,
                            children: [
                              SettingButtonOption(
                                text: "${t.actions.downloadAllAlbums} :",
                                action: t.general.download,
                                onPressed: () async {
                                  final downloadManager = context
                                      .read<DownloadManager>();
                                  if (!NetworkInfo().isServerRecheable()) {
                                    AppNotificationManager.of(context).notify(
                                      context,
                                      title: t.notifications.offline.title,
                                      message: t.notifications.offline.message,
                                      type: AppNotificationType.danger,
                                    );
                                    return;
                                  }

                                  if (!await appConfirm(
                                    context,
                                    title: t.confirms.title,
                                    content: t.confirms.downloadAllAlbums,
                                    textOK: t.general.download,
                                    isDangerous: true,
                                  )) {
                                    return;
                                  }

                                  final streamController =
                                      StreamController<double>();

                                  final stream = streamController.stream
                                      .asBroadcastStream();

                                  final loadingWidget = OverlayEntry(
                                    builder: (context) => StreamBuilder(
                                      stream: stream,
                                      builder: (context, snapshot) {
                                        return AppPageLoader(
                                          value: snapshot.data,
                                        );
                                      },
                                    ),
                                  );

                                  if (context.mounted) {
                                    Overlay.of(
                                      context,
                                      rootOverlay: true,
                                    ).insert(loadingWidget);
                                  }

                                  try {
                                    await downloadManager.downloadAllAlbums(
                                      streamController,
                                    );
                                    streamController.close();

                                    loadingWidget.remove();

                                    if (!context.mounted) {
                                      return;
                                    }

                                    AppNotificationManager.of(context).notify(
                                      context,
                                      message: t
                                          .notifications
                                          .downloadAllAlbumsStarted
                                          .message,
                                    );
                                  } catch (_) {
                                    streamController.close();
                                    if (context.mounted) {
                                      AppNotificationManager.of(context).notify(
                                        context,
                                        title: t
                                            .notifications
                                            .somethingWentWrong
                                            .title,
                                        message: t
                                            .notifications
                                            .somethingWentWrong
                                            .message,
                                        type: AppNotificationType.danger,
                                      );
                                    }
                                    loadingWidget.remove();
                                  }
                                },
                              ),
                              const Divider(height: 0),
                              SettingButtonOption(
                                text:
                                    "${t.actions.removeAllDownloadedTracks} :",
                                action: t.actions.removeAll,
                                onPressed: () async {
                                  final downloadManager = context
                                      .read<DownloadManager>();

                                  if (!await appConfirm(
                                    context,
                                    title: t.confirms.title,
                                    content:
                                        t.confirms.deleteAllDownloadedTracks,
                                    textOK: t.confirms.delete,
                                    isDangerous: true,
                                  )) {
                                    return;
                                  }

                                  final loadingWidget = OverlayEntry(
                                    builder: (context) => const AppPageLoader(),
                                  );

                                  if (context.mounted) {
                                    Overlay.of(
                                      context,
                                      rootOverlay: true,
                                    ).insert(loadingWidget);
                                  }

                                  try {
                                    await downloadManager.removeAllDownloads();
                                    loadingWidget.remove();

                                    if (!context.mounted) {
                                      return;
                                    }

                                    AppNotificationManager.of(context).notify(
                                      context,
                                      message: t
                                          .notifications
                                          .allDownloadHaveBeenDeleted
                                          .message,
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      AppNotificationManager.of(context).notify(
                                        context,
                                        title: t
                                            .notifications
                                            .somethingWentWrong
                                            .title,
                                        message: t
                                            .notifications
                                            .somethingWentWrong
                                            .message,
                                        type: AppNotificationType.danger,
                                      );
                                    }

                                    loadingWidget.remove();
                                  }
                                },
                                isDanger: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SettingPannel(
                            title: t.general.debug,
                            children: [
                              SettingToggleOption(
                                text: "${t.settings.showPlayerDebugOverlay} :",
                                value: settings.showPlayerDebugOverlay,
                                onToggle: (value) => viewModel.setSettings(
                                  settings.copyWith(
                                    showPlayerDebugOverlay: value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            text: t.actions.logout,
                            type: AppButtonType.primary,
                            onPressed: () =>
                                context.read<AuthViewModel>().logout(),
                          ),
                          SizedBox(height: padding),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
