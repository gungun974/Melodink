import 'dart:async';

import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:melodink_client/features/settings/data/repository/settings_repository.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/data/repository/sync_shared_played_track_repository.dart';

class SharedPlayedTrackerManager {
  Timer? _timer;
  bool _shouldStop = false;

  final PlayedTrackRepository playedTrackRepository;
  final SyncSharedPlayedTrackRepository syncSharedPlayedTrackRepository;

  SharedPlayedTrackerManager({
    required this.playedTrackRepository,
    required this.syncSharedPlayedTrackRepository,
  }) {
    _scheduleSync();
  }

  _scheduleSync() async {
    await _execute();

    _timer = Timer(const Duration(seconds: 45), () async {
      if (_shouldStop) {
        return;
      }

      await _execute();

      _scheduleSync();
    });
  }

  _execute() async {
    try {
      await getMelodinkInstanceSupportDirectory();
    } catch (_) {
      return await _scheduleSync();
    }

    try {
      await syncSharedPlayedTrackRepository.fetchSharedPlayedTracks();
    } catch (e) {
      mainLogger.e(e);
    }

    try {
      await playedTrackRepository.checkAndUpdateAllTrackHistoryCache();
    } catch (e) {
      mainLogger.e(e);
    }

    try {
      final settings = await SettingsRepository().getSettings();

      if (settings.shareAllHistoryTrackingToServer) {
        await syncSharedPlayedTrackRepository.uploadNotSharedTracks();
      }
    } catch (e) {
      mainLogger.e(e);
    }
  }

  void dispose() {
    _shouldStop = true;
    _timer?.cancel();
    _timer = null;
  }
}
