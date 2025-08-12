import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/features/sync/data/repository/sync_repository.dart';
import 'package:melodink_client/features/sync/domain/manager/sync_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_manager_provider.g.dart';

@Riverpod(keepAlive: true)
SyncManager syncManager(Ref ref) {
  final manager = SyncManager(
    syncRepository: ref.watch(syncRepositoryProvider),
  );

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
}
