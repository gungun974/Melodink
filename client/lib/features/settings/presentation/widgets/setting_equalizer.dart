import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:melodink_client/core/widgets/app_switch.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/domain/entities/equalizer.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class SettingEqualizer extends riverpod.HookConsumerWidget {
  const SettingEqualizer({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final viewModel = context.read<SettingsViewModel>();

    final bands = [
      useState(viewModel.state?.equalizer.bands[60] ?? 0),
      useState(viewModel.state?.equalizer.bands[150] ?? 0),
      useState(viewModel.state?.equalizer.bands[400] ?? 0),
      useState(viewModel.state?.equalizer.bands[1000] ?? 0),
      useState(viewModel.state?.equalizer.bands[2400] ?? 0),
      useState(viewModel.state?.equalizer.bands[15000] ?? 0),
    ];

    useOnListenableChange(viewModel, () {
      final settings = viewModel.state;
      if (settings == null) {
        return;
      }
      bands[0].value = settings.equalizer.bands[60] ?? 0;
      bands[1].value = settings.equalizer.bands[150] ?? 0;
      bands[2].value = settings.equalizer.bands[400] ?? 0;
      bands[3].value = settings.equalizer.bands[1000] ?? 0;
      bands[4].value = settings.equalizer.bands[2400] ?? 0;
      bands[5].value = settings.equalizer.bands[15000] ?? 0;
    });

    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, _) {
        final settings = viewModel.state;
        if (settings == null) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.general.equalizer,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                        letterSpacing: 18 * 0.04,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppSwitch(
                    value: settings.equalizer.enabled,
                    onToggle: (value) async {
                      viewModel.setSettings(
                        settings.copyWith(
                          equalizer: AppEqualizer(
                            enabled: value,
                            bands: settings.equalizer.bands,
                          ),
                        ),
                      );

                      await audioController.updatePlayerEqualizer();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AbsorbPointer(
                absorbing: !settings.equalizer.enabled,
                child: Opacity(
                  opacity: settings.equalizer.enabled ? 1 : 0.4,
                  child: Row(
                    children: ["60Hz", "150Hz", "400Hz", "1KHz", "2.4KHz", "15KHz"]
                        .indexed
                        .map(
                          (entry) => Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "${bands[entry.$1].value.toStringAsFixed(2)}dB",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 14,
                                    letterSpacing: 14 * 0.04,
                                  ),
                                ),
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    onChanged: (value) {
                                      if (value > -0.25 && value < 0.25) {
                                        bands[entry.$1].value = 0;
                                        return;
                                      }
                                      bands[entry.$1].value = value;
                                    },
                                    onChangeEnd: (_) async {
                                      viewModel.setSettings(
                                        settings.copyWith(
                                          equalizer: AppEqualizer(
                                            enabled: settings.equalizer.enabled,
                                            bands: {
                                              60: bands[0].value,
                                              150: bands[1].value,
                                              400: bands[2].value,
                                              1000: bands[3].value,
                                              2400: bands[4].value,
                                              15000: bands[5].value,
                                            },
                                          ),
                                        ),
                                      );

                                      await audioController
                                          .updatePlayerEqualizer();
                                    },
                                    value: bands[entry.$1].value,
                                    min: -12,
                                    max: 12,
                                  ),
                                ),
                                Text(
                                  entry.$2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 14,
                                    letterSpacing: 14 * 0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
