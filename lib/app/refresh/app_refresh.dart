import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/data/sync_coordinator.dart';
import '../../ui/ui.dart';

/// Keeps the app's data fresh as the user comes and goes.
///
/// First sign-in and a return after more than [away] show a loading screen
/// over the same screen while everything is synced; a shorter absence just
/// pulls to refresh the visible screen, as a gesture would.
class AppRefresh {
  AppRefresh({
    required this.coordinator,
    required this.registry,
    this.away = const Duration(minutes: 5),
    this.cap = const Duration(seconds: 10),
  });

  final SyncCoordinator coordinator;
  final RefreshRegistry registry;
  final Duration away;
  final Duration cap;

  /// True while the loading screen should cover the app.
  final busy = ValueNotifier<bool>(false);

  DateTime? _hiddenAt;

  /// Signed in: load what the device holds, then sync everything. With
  /// nothing on the device yet, the loading screen waits for the sync.
  Future<void> start(String userId) async {
    await coordinator.hydrate(userId);
    final first = !coordinator.hasAllData;
    if (first) busy.value = true;
    try {
      await coordinator.sync().timeout(cap, onTimeout: () => false);
    } finally {
      if (first) busy.value = false;
    }
  }

  void onHidden() => _hiddenAt ??= DateTime.now();

  Future<void> onResumed({required bool signedIn}) async {
    final since = _hiddenAt;
    _hiddenAt = null;
    if (!signedIn || since == null) return;
    if (DateTime.now().difference(since) <= away) {
      unawaited(registry.refreshCurrent());
      return;
    }
    busy.value = true;
    try {
      await Future.wait([
        coordinator.sync(),
        registry.refreshCurrent(),
      ]).timeout(cap, onTimeout: () => const []);
    } finally {
      busy.value = false;
    }
  }

  void dispose() => busy.dispose();
}
