import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/data/sync_coordinator.dart';
import '../../ui/ui.dart';

/// Keeps the app's data fresh as the user comes and goes.
///
/// First sign-in and a return after more than [away] show a loading screen
/// over the same screen while everything is synced; a shorter absence just
/// pulls to refresh the visible screen, as a gesture would.
///
/// A new day also syncs once, quietly: at local midnight while the app is
/// open (plus up to a minute, so devices don't all ask at 0:00:00), and on a
/// return after the date changed. What depends on "today" (the next
/// occurrence, what came due) then moves on its own.
class AppRefresh {
  AppRefresh({
    required this.coordinator,
    required this.registry,
    this.away = const Duration(minutes: 5),
    this.cap = const Duration(seconds: 10),
    DateTime Function()? now,
    Random? random,
  }) : _now = now ?? DateTime.now,
       _random = random ?? Random();

  final SyncCoordinator coordinator;
  final RefreshRegistry registry;
  final Duration away;
  final Duration cap;
  final DateTime Function() _now;
  final Random _random;

  /// True while the loading screen should cover the app.
  final busy = ValueNotifier<bool>(false);

  DateTime? _hiddenAt;
  DateTime? _syncedDay;
  Timer? _midnight;

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
    _markSynced();
  }

  void onHidden() => _hiddenAt ??= _now();

  Future<void> onResumed({required bool signedIn}) async {
    final since = _hiddenAt;
    _hiddenAt = null;
    if (!signedIn || since == null) return;
    if (_now().difference(since) <= away) {
      unawaited(_isNewDay ? _syncDay() : registry.refreshCurrent());
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
    _markSynced();
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  bool get _isNewDay => _syncedDay != null && _day(_now()) != _syncedDay;

  Future<void> _syncDay() async {
    if (coordinator.userId == null) return;
    await Future.wait([
      coordinator.sync(),
      registry.refreshCurrent(),
    ]).timeout(cap, onTimeout: () => const []);
    _markSynced();
  }

  void _markSynced() {
    _syncedDay = _day(_now());
    _midnight?.cancel();
    final now = _now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(
      next.difference(now) + Duration(seconds: _random.nextInt(61)),
      () => unawaited(_syncDay()),
    );
  }

  void dispose() {
    _midnight?.cancel();
    busy.dispose();
  }
}
