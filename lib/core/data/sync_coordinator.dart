import 'dart:async';

import 'package:flutter/foundation.dart';

import 'sync_repository.dart';
import 'sync_set.dart';
import 'sync_store.dart';

typedef SyncApply = void Function(Map<String, dynamic> body);
typedef SyncFailed = void Function(SyncError error);

/// One finished request to `/sync`, kept for the hub's debug page.
class SyncRound {
  const SyncRound({
    required this.at,
    required this.requested,
    required this.returned,
    required this.unchanged,
    required this.errors,
    required this.duration,
    this.failure,
    this.fromFallback = false,
  });

  final DateTime at;
  final Set<SyncSet> requested;
  final Set<SyncSet> returned;
  final Set<SyncSet> unchanged;
  final Map<SyncSet, String> errors;
  final Duration duration;
  final String? failure;
  final bool fromFallback;
}

/// The one place the app asks the server what changed. Every cache attaches
/// to its dataset, gets what the device holds at once, and gets the new body
/// whenever a sync brings one.
class SyncCoordinator extends ChangeNotifier {
  SyncCoordinator({
    required SyncRepository repository,
    required SyncStore store,
    this.debounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _store = store;

  static const _roundsKept = 50;

  final SyncRepository _repository;
  final SyncStore _store;
  final Duration debounce;

  final _appliers = <SyncSet, SyncApply>{};
  final _failed = <SyncSet, SyncFailed>{};
  final _entries = <SyncSet, SyncEntry>{};
  final _versions = <String, String>{};
  final _rounds = <SyncRound>[];

  /// Page-data keys whose version moved; the caches that hold them reload.
  void Function(Set<SyncKey> keys)? onPageDataChanged;

  /// Datasets a sync replaced with different data than the device held.
  void Function(Set<SyncSet> sets)? onDatasetsChanged;

  String? _userId;
  int _epoch = 0;

  final _wanted = <SyncSet>{};
  Future<bool>? _loop;

  final _debounced = <SyncSet>{};
  Timer? _timer;

  String? get userId => _userId;
  List<SyncRound> get rounds => List.unmodifiable(_rounds);
  Map<String, String> get versions => Map.unmodifiable(_versions);

  /// What the app holds per dataset (the debug page compares it with [versions]).
  Map<SyncSet, String> get held => {
    for (final e in _entries.entries) e.key: e.value.v,
  };

  bool hasData(SyncSet set) => _entries.containsKey(set);

  /// True once the device holds every dataset (a first sign-in does not).
  bool get hasAllData => SyncSet.values.every(_entries.containsKey);

  /// [apply] gets the dataset's body now if the device holds it, and again on every update.
  void attach(SyncSet set, SyncApply apply, {SyncFailed? onError}) {
    _appliers[set] = apply;
    if (onError != null) _failed[set] = onError;
    final entry = _entries[set];
    if (entry != null) _applySafely(set, entry.body);
  }

  void detach(SyncSet set, SyncApply apply) {
    if (_appliers[set] != apply) return;
    _appliers.remove(set);
    _failed.remove(set);
  }

  /// Hands the cache the body the device holds again (a sync that found nothing new).
  void reapply(SyncSet set) {
    final entry = _entries[set];
    if (entry != null) _applySafely(set, entry.body);
  }

  /// Loads what the device holds for [userId] into the caches.
  Future<void> hydrate(String userId) async {
    if (_userId != null && _userId != userId) _reset();
    _userId = userId;
    final epoch = _epoch;
    await _store.clearOthers(userId);
    final saved = await _store.readAll(userId);
    if (epoch != _epoch) return;
    for (final e in saved.entries) {
      if (_entries.containsKey(e.key)) continue;
      _entries[e.key] = e.value;
      _applySafely(e.key, e.value.body);
    }
    notifyListeners();
  }

  /// Hydrate, then bring everything up to date in the background.
  Future<bool> start(String userId) async {
    await hydrate(userId);
    return sync();
  }

  /// Deletes what is saved on the device; the caches keep what they hold until
  /// the app restarts and loads from the server.
  Future<void> clearDeviceData() async {
    final id = _userId;
    if (id != null) await _store.clear(id);
  }

  /// Signs out or switches user: forgets everything, here and on the device.
  Future<void> clear() async {
    final old = _userId;
    _reset();
    _userId = null;
    if (old != null) await _store.clear(old);
    notifyListeners();
  }

  void _reset() {
    _epoch++;
    _timer?.cancel();
    _debounced.clear();
    _wanted.clear();
    _entries.clear();
    _versions.clear();
    _rounds.clear();
  }

  /// Asks the server for [sets] (none = every dataset). Calls made while a
  /// sync runs wait for it and go out together as the next round; never two at
  /// once. Completes with false if a round failed or a dataset came back in error.
  Future<bool> sync([Set<SyncSet>? sets]) {
    if (_userId == null) return Future.value(false);
    _wanted.addAll(sets ?? SyncSet.values);
    return _loop ??= _drain();
  }

  Future<bool> _drain() async {
    var ok = true;
    try {
      while (_wanted.isNotEmpty) {
        final batch = {..._wanted};
        _wanted.clear();
        ok = await _round(batch) && ok;
      }
    } finally {
      _loop = null;
    }
    return ok;
  }

  Future<bool> _round(Set<SyncSet> batch) async {
    final epoch = _epoch;
    final userId = _userId!;
    final started = DateTime.now();
    final have = {
      for (final s in batch)
        if (_entries[s] != null && _entries[s]!.v.isNotEmpty) s: _entries[s]!.v,
    };
    try {
      final result = await _repository.sync(
        want: batch.length == SyncSet.values.length ? null : batch,
        have: have,
      );
      if (epoch != _epoch) return false;
      final changedSets = <SyncSet>{};
      for (final e in result.data.entries) {
        final before = _entries[e.key];
        if (before != null && before.v != e.value.v) changedSets.add(e.key);
        final entry = SyncEntry(
          v: e.value.v,
          body: e.value.body,
          savedAt: result.syncedAt,
        );
        _entries[e.key] = entry;
        unawaited(_store.write(userId, e.key, entry));
        _applySafely(e.key, entry.body);
      }
      for (final e in result.errors.entries) {
        _failed[e.key]?.call(e.value);
      }
      _remember(
        SyncRound(
          at: started,
          requested: batch,
          returned: result.data.keys.toSet(),
          unchanged: result.unchanged,
          errors: {for (final e in result.errors.entries) e.key: e.value.code},
          duration: DateTime.now().difference(started),
          fromFallback: result.fromFallback,
        ),
      );
      _ingestVersions(result.versions, fromHeader: false);
      if (changedSets.isNotEmpty) onDatasetsChanged?.call(changedSets);
      return result.errors.isEmpty;
    } catch (e) {
      if (epoch != _epoch) return false;
      for (final s in batch) {
        _failed[s]?.call(SyncError(code: 'SYNC_FAILED', message: '$e'));
      }
      _remember(
        SyncRound(
          at: started,
          requested: batch,
          returned: const {},
          unchanged: const {},
          errors: const {},
          duration: DateTime.now().difference(started),
          failure: '$e',
        ),
      );
      return false;
    }
  }

  void _remember(SyncRound round) {
    _rounds.add(round);
    if (_rounds.length > _roundsKept) _rounds.removeAt(0);
    notifyListeners();
  }

  void _applySafely(SyncSet set, Map<String, dynamic> body) {
    try {
      _appliers[set]?.call(body);
    } catch (e) {
      _failed[set]?.call(SyncError(code: 'PARSE_ERROR', message: '$e'));
    }
  }

  /// Versions from a write's `X-Sync-Versions` header.
  void onVersions(Map<String, String> versions) =>
      _ingestVersions(versions, fromHeader: true);

  void _ingestVersions(
    Map<String, String> versions, {
    required bool fromHeader,
  }) {
    if (_userId == null || versions.isEmpty) return;
    final changedKeys = <SyncKey>{};
    final staleSets = <SyncSet>{};
    for (final e in versions.entries) {
      final set = SyncSet.fromWire(e.key);
      if (set != null) {
        _versions[e.key] = e.value;
        if (fromHeader && _entries[set]?.v != e.value) staleSets.add(set);
        continue;
      }
      final key = SyncKey.fromWire(e.key);
      if (key == null) continue;
      final before = _versions[e.key];
      _versions[e.key] = e.value;
      if (before != null && before != e.value) changedKeys.add(key);
    }
    if (staleSets.isNotEmpty) _scheduleSync(staleSets);
    if (changedKeys.isNotEmpty) onPageDataChanged?.call(changedKeys);
    notifyListeners();
  }

  void _scheduleSync(Set<SyncSet> sets) {
    _debounced.addAll(sets);
    _timer?.cancel();
    _timer = Timer(debounce, () {
      final batch = {..._debounced};
      _debounced.clear();
      unawaited(sync(batch));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
