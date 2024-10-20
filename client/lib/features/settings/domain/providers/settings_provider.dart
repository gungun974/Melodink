import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  late final SettingsRepository _settingsRepository;

  @override
  Future<AppSettings> build() async {
    _settingsRepository = ref.read(settingsRepositoryProvider);

    return await _settingsRepository.getSettings();
  }

  setSettings(AppSettings newSettings) async {
    await _settingsRepository.setSettings(
      newSettings,
    );

    state = AsyncData(await _settingsRepository.getSettings());
  }
}
