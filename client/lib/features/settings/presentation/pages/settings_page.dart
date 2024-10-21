import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/auth/domain/providers/auth_provider.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';
import 'package:melodink_client/features/settings/presentation/widgets/server_info.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_button_option.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_dropdown_option.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_pannel.dart';
import 'package:melodink_client/features/settings/presentation/widgets/setting_toggle_option.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsNotifierProvider).valueOrNull;

    if (settings == null) {
      return const AppPageLoader();
    }

    return AppNavigationHeader(
      alwayShow: true,
      title: const Text("Settings"),
      child: AppScreenTypeLayoutBuilder(
        builder: (context, size) {
          final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

          return SingleChildScrollView(
            child: MaxContainer(
              maxWidth: 512,
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: padding),
                  const ServerInfo(),
                  const SizedBox(height: 16),
                  SettingPannel(
                    title: "Appearance",
                    children: [
                      SettingDropdownOption(
                        text: "Theme :",
                        value: settings.theme,
                        onChanged: (theme) {
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .setSettings(
                                settings.copyWith(
                                  theme: theme,
                                ),
                              );
                        },
                        items: const [
                          DropdownMenuItem(
                            value: AppSettingTheme.base,
                            child: Text("Default"),
                          ),
                          DropdownMenuItem(
                            value: AppSettingTheme.dark,
                            child: Text("Dark"),
                          ),
                          DropdownMenuItem(
                            value: AppSettingTheme.dynamic,
                            child: Text("Dynamic"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SettingDropdownOption(
                        text: "Desktop Player bar position :",
                        value: settings.playerBarPosition,
                        onChanged: (position) {
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .setSettings(
                                settings.copyWith(
                                  playerBarPosition: position,
                                ),
                              );
                        },
                        items: const [
                          DropdownMenuItem(
                            value: AppSettingPlayerBarPosition.bottom,
                            child: Text("Bottom"),
                          ),
                          DropdownMenuItem(
                            value: AppSettingPlayerBarPosition.top,
                            child: Text("Top"),
                          ),
                          DropdownMenuItem(
                            value: AppSettingPlayerBarPosition.side,
                            child: Text("Side"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SettingPannel(
                    title: "Playing",
                    children: [
                      SettingToggleOption(
                        text: "Remember loop and shuffle across restarts :",
                        value: settings.rememberLoopAndShuffleAcrossRestarts,
                        onToggle: (value) {
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .setSettings(
                                settings.copyWith(
                                  rememberLoopAndShuffleAcrossRestarts: value,
                                ),
                              );
                        },
                      ),
                      const SizedBox(height: 8),
                      SettingToggleOption(
                        text: "Keep last playing list across restarts :",
                        value: settings.keepLastPlayingListAcrossRestarts,
                        onToggle: (value) {
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .setSettings(
                                settings.copyWith(
                                  keepLastPlayingListAcrossRestarts: value,
                                ),
                              );
                        },
                      ),
                      const SizedBox(height: 8),
                      SettingToggleOption(
                        text: "Auto scroll view to current track :",
                        value: settings.autoScrollViewToCurrentTrack,
                        onToggle: (value) {
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .setSettings(
                                settings.copyWith(
                                  autoScrollViewToCurrentTrack: value,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SettingPannel(
                    title: "Tracking",
                    children: [
                      SettingToggleOption(
                        text: "Enable history tracking :",
                        value: settings.enableHistoryTracking,
                        onToggle: (value) {
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .setSettings(
                                settings.copyWith(
                                  enableHistoryTracking: value,
                                ),
                              );
                        },
                      ),
                      const SizedBox(height: 8),
                      SettingToggleOption(
                        text: "Share all history tracking to server :",
                        value: settings.shareAllHistoryTrackingToServer,
                        onToggle: (value) {
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .setSettings(
                                settings.copyWith(
                                  shareAllHistoryTrackingToServer: value,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SettingPannel(
                    title: "Download",
                    children: [
                      SettingButtonOption(
                        text: "Download all albums :",
                        action: "Download",
                        onPressed: () {},
                      ),
                      const SizedBox(height: 8),
                      SettingButtonOption(
                        text: "Remove all offline tracks :",
                        action: "Remove all",
                        onPressed: () {},
                        isDanger: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer(builder: (context, ref, _) {
                    return AppButton(
                      text: "Logout",
                      type: AppButtonType.primary,
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).logout();
                      },
                    );
                  }),
                  SizedBox(height: padding),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
