import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/data/sync_coordinator.dart';
import 'package:chubi_pocket/core/data/sync_repository.dart';
import 'package:chubi_pocket/core/data/sync_set.dart';
import 'package:chubi_pocket/core/data/sync_store.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/providers_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/project_directory_cubit.dart';
import 'package:chubi_pocket/features/recurring/presentation/cubit/recurring_directory_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/form_options.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/tx_form_options_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

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

RepositoryProvider<SyncCoordinator> syncCoordinatorProvider([
  SyncCoordinator? coordinator,
]) => RepositoryProvider<SyncCoordinator>.value(
  value: coordinator ?? testCoordinator(),
);

BlocProvider<ProvidersCubit> providersCubitProvider() =>
    BlocProvider<ProvidersCubit>(
      create: (_) => ProvidersCubit(coordinator: testCoordinator()),
    );

BlocProvider<ProjectDirectoryCubit> projectDirectoryProvider() =>
    BlocProvider<ProjectDirectoryCubit>(
      create: (_) => ProjectDirectoryCubit(coordinator: testCoordinator()),
    );

BlocProvider<DebtDirectoryCubit> debtDirectoryProvider([
  DebtDirectoryCubit? cubit,
]) => cubit != null
    ? BlocProvider<DebtDirectoryCubit>.value(value: cubit)
    : BlocProvider<DebtDirectoryCubit>(
        create: (_) => DebtDirectoryCubit(coordinator: testCoordinator()),
      );

/// A recurring directory already holding [rules] (the `data` rows of a
/// `/recurring` body), as if the sync had landed.
RecurringDirectoryCubit recurringDirectoryWith([
  List<Map<String, dynamic>> rules = const [],
  Map<String, dynamic>? summary,
]) {
  final cubit = RecurringDirectoryCubit(coordinator: testCoordinator());
  cubit.applySync({'data': rules, 'summary': summary});
  return cubit;
}

BlocProvider<RecurringDirectoryCubit> recurringDirectoryProvider([
  RecurringDirectoryCubit? cubit,
]) => BlocProvider<RecurringDirectoryCubit>.value(
  value: cubit ?? recurringDirectoryWith(),
);

class _MockTxFormOptions extends MockCubit<TxFormOptionsState>
    implements TxFormOptionsCubit {}

/// The form options a quick-create sheet reads. Starts landed with [options];
/// pass `landed: false` and call [land] to see the skeleton first.
class FakeTxFormOptions {
  FakeTxFormOptions({
    bool landed = true,
    TxFormOptions options = const TxFormOptions(),
  }) : _options = options {
    _state = landed ? _loaded(options) : const TxFormOptionsState();
    when(() => cubit.state).thenAnswer((_) => _state);
    when(() => cubit.stream).thenAnswer((_) => _changes.stream);
    when(cubit.load).thenAnswer((_) async {});
    when(cubit.loadIfNeeded).thenAnswer((_) async {});
  }

  final cubit = _MockTxFormOptions();
  final _changes = StreamController<TxFormOptionsState>.broadcast();
  final TxFormOptions _options;
  late TxFormOptionsState _state;

  static TxFormOptionsState _loaded(TxFormOptions o) =>
      TxFormOptionsState(status: TxFormOptionsStatus.loaded, options: o);

  void land([TxFormOptions? options]) {
    _state = _loaded(options ?? _options);
    _changes.add(_state);
  }

  BlocProvider<TxFormOptionsCubit> get provider =>
      BlocProvider<TxFormOptionsCubit>.value(value: cubit);
}
