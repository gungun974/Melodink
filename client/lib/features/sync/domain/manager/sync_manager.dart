import 'dart:async';

import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/features/sync/data/repository/sync_repository.dart';

class SyncManager {
  Timer? _timer;
  bool _shouldStop = false;

  final SyncRepository syncRepository;

  SyncManager({required this.syncRepository}) {
    _scheduleSync();
  }

  Future<void> _scheduleSync() async {
    try {
      await _execute();
    } finally {
      _timer = Timer(const Duration(seconds: 120), () async {
        if (_shouldStop) {
          return;
        }

        try {
          await _execute();
        } finally {
          _scheduleSync();
        }
      });
    }
  }

  Future<void> _execute() async {
    // Is Ready to sync
    try {
      await getMelodinkInstanceSupportDirectory();
    } catch (_) {
      return;
    }

    await syncRepository.performSync();
    await syncRepository.uploadPlayedTracks();
  }

  void dispose() {
    _shouldStop = true;
    _timer?.cancel();
    _timer = null;
  }
}
