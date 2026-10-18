import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_exception.dart';
import 'sync_coordinator.dart';
import 'sync_set.dart';

/// A cache cubit whose data is one `/sync` dataset: the coordinator hands it
/// the body (from the device first, then from every sync), so it never fetches
/// the list itself.
mixin SyncBacked<S> on BlocBase<S> {
  SyncCoordinator get syncCoordinator;
  SyncSet get syncSet;

  bool get syncLoading;
  void markSyncLoading();
  void applySync(Map<String, dynamic> body);
  void syncFailed(ApiException error);

  void bindSync() => syncCoordinator.attach(
    syncSet,
    applySync,
    onError: (e) => syncFailed(ApiException(code: e.code, message: e.message)),
  );

  bool get holdsSyncData => syncCoordinator.hasData(syncSet);

  /// Syncs this dataset (the loading state only when there is nothing to show).
  Future<void> loadSynced() async {
    if (!holdsSyncData) markSyncLoading();
    // Signing in: the start-up sync fills this cache when it lands.
    if (syncCoordinator.userId == null) return;
    await syncCoordinator.sync({syncSet});
    if (!syncLoading) return;
    if (holdsSyncData) {
      syncCoordinator.reapply(syncSet);
    } else {
      syncFailed(
        const ApiException(
          code: 'SYNC_UNAVAILABLE',
          message: 'Could not load the data',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    syncCoordinator.detach(syncSet, applySync);
    return super.close();
  }
}
