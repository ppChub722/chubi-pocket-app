import 'dart:io';

import 'package:chubi_pocket/core/data/sync_coordinator.dart';
import 'package:chubi_pocket/core/data/sync_repository.dart';
import 'package:chubi_pocket/core/data/sync_set.dart';
import 'package:chubi_pocket/core/data/sync_store.dart';

class _IdleSyncRepository implements SyncRepository {
  @override
  Future<SyncResult> sync({
    Set<SyncSet>? want,
    Map<SyncSet, String> have = const {},
  }) async => SyncResult(
    syncedAt: DateTime.utc(2026),
    versions: const {},
    data: const {},
    unchanged: const {},
    errors: const {},
  );
}

/// A coordinator for tests that put state straight into a cache: it never
/// started for a user, so a `load()` waits and no request goes out.
SyncCoordinator testCoordinator() => SyncCoordinator(
  repository: _IdleSyncRepository(),
  store: SyncStore(root: () async => Directory.systemTemp),
);
