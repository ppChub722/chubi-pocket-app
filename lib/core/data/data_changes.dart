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
  formOptions,
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

const _tx = {
  DataTable.transactions,
  DataTable.accounts,
  DataTable.dashboard,
  DataTable.budgets,
  DataTable.formOptions,
};
const _people = {DataTable.debts, DataTable.contacts};

/// THE table of "a write here touches these" — by the request's [method],
/// [path] (no query) and [payload] (the body sent, when it's a map). One
/// place to read and to change. A write whose payload can't tell (a DELETE)
/// counts as touching everything it might.
Set<DataTable> tablesForWrite(String method, String path, Object? payload) {
  final m = method.toUpperCase();
  if (m == 'GET' || m == 'HEAD') return const {};
  final p = path.startsWith('/') ? path : '/$path';
  final body = payload is Map ? payload : const <String, dynamic>{};
  final deleting = m == 'DELETE';
  bool under(String prefix) => p == prefix || p.startsWith('$prefix/');
  bool has(String key) {
    final v = body[key];
    return v != null && !(v is List && v.isEmpty) && v != false;
  }

  if (under('/transactions')) {
    if (p.endsWith('/tags')) return const {DataTable.transactions};
    return {
      ..._tx,
      if (deleting || p.endsWith('/splits') || has('splits')) ..._people,
      if (deleting || has('source_project_transaction_id')) DataTable.projects,
      if (deleting) DataTable.savingGoals,
    };
  }
  if (under('/personal-debts')) {
    final moneyMoves =
        deleting ||
        has('create_transaction') ||
        has('account_id') ||
        p.contains('/split-requests/') ||
        p.contains('/split-changes/');
    return {..._people, if (moneyMoves) ..._tx};
  }
  if (under('/contacts')) {
    return const {DataTable.contacts, DataTable.debts, DataTable.projects};
  }
  if (under('/accounts')) {
    if (p == '/accounts/reorder') {
      return const {DataTable.accounts, DataTable.formOptions};
    }
    return {
      ..._tx,
      if (p.contains('/members') || p.contains('/invites/')) DataTable.contacts,
    };
  }
  if (under('/categories')) {
    if (p == '/categories/reorder') {
      return const {DataTable.categories, DataTable.formOptions};
    }
    return const {
      DataTable.categories,
      DataTable.budgets,
      DataTable.dashboard,
      DataTable.formOptions,
      DataTable.transactions,
    };
  }
  if (under('/tags')) {
    return const {DataTable.tags, DataTable.formOptions, DataTable.transactions};
  }
  if (under('/budgets')) return const {DataTable.budgets, DataTable.dashboard};
  if (under('/saving-goals') || under('/saving-entries')) {
    return const {
      DataTable.savingGoals,
      DataTable.accounts,
      DataTable.transactions,
      DataTable.dashboard,
    };
  }
  if (under('/projects')) {
    if (RegExp(r'^/projects/[^/]+/tags').hasMatch(p)) {
      return const {DataTable.projects};
    }
    return {
      DataTable.projects,
      DataTable.formOptions,
      if (p.contains('/members')) DataTable.contacts,
      if (deleting ||
          p.contains('/bills') ||
          p.contains('/project-transactions') ||
          p == '/projects/quick')
        ..._tx,
      if (deleting || p.contains('/bills')) ..._people,
    };
  }
  if (under('/recurring') || under('/recurring-items')) {
    return {DataTable.pending, DataTable.dashboard, if (p.contains('/create') || deleting) ..._tx};
  }
  if (under('/pending-transactions')) {
    final submits = p.contains('/submit');
    return {
      DataTable.pending,
      DataTable.dashboard,
      if (submits) ..._tx,
      if (submits) ..._people,
    };
  }
  // auth, the profile, notification reads / settings: nothing cached.
  return const {};
}
