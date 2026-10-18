import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// The app's cached data, by what it holds — what a write can leave stale.
enum DataTable {
  transactions,
  accounts,
  categories,
  tags,
  contacts,
  debts,
  dashboard,
  budgets,
  savingGoals,
  projects,
  pending,
}

typedef DataRefresh = Future<void> Function();

/// The one "data changed" signal (owner 2026-10-18). Every successful write
/// goes through the API client, which asks [tablesForWrite] what it touched
/// and calls [changed]; each cache that holds those tables reloads itself
/// (only if it had loaded — a cache nobody opened stays untouched).
/// [refreshAll] reloads every cache that has loaded (coming back to the app
/// after a while).
class DataChanges {
  DataChanges._();

  static final DataChanges instance = DataChanges._();

  final _subs = <_Sub>[];

  /// [refresh] runs when any of [tables] changes. Returns the unsubscribe.
  void Function() listen(Set<DataTable> tables, DataRefresh refresh) {
    final sub = _Sub(tables, refresh);
    _subs.add(sub);
    return () => _subs.remove(sub);
  }

  Future<void> changed(Set<DataTable> tables) => tables.isEmpty
      ? Future.value()
      : _run([
          for (final s in List.of(_subs))
            if (s.tables.any(tables.contains)) s,
        ]);

  Future<void> refreshAll() => _run(List.of(_subs));

  Future<void> _run(List<_Sub> subs) async {
    await Future.wait([for (final s in subs) _safe(s.refresh)]);
  }

  static Future<void> _safe(DataRefresh refresh) async {
    try {
      await refresh();
    } catch (_) {
      // A cache that fails to reload keeps its data and shows its own error.
    }
  }
}

class _Sub {
  _Sub(this.tables, this.refresh);
  final Set<DataTable> tables;
  final DataRefresh refresh;
}

/// For a cache cubit: [refreshOn] reloads it when its tables change; the
/// subscription ends with the cubit.
mixin RefreshOnDataChange<S> on BlocBase<S> {
  void Function()? _offDataChanges;

  void refreshOn(Set<DataTable> tables, DataRefresh refresh) {
    _offDataChanges?.call();
    _offDataChanges = DataChanges.instance.listen(tables, refresh);
  }

  @override
  Future<void> close() {
    _offDataChanges?.call();
    return super.close();
  }
}
