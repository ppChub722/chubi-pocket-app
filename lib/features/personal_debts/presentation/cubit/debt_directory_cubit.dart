import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/sync_backed.dart';
import '../../../../core/data/sync_coordinator.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/debt_directory.dart';
import '../../domain/debt_ledger.dart';

enum DebtDirectoryStatus { initial, loading, loaded, error }

class DebtDirectoryState extends Equatable {
  const DebtDirectoryState({
    this.people = const [],
    this.status = DebtDirectoryStatus.initial,
    this.error,
  });

  /// Everyone with an entry, settled people included.
  final List<PersonBalance> people;
  final DebtDirectoryStatus status;
  final ApiException? error;

  DebtTotals get totals => debtTotalsOf(people);

  @override
  List<Object?> get props => [people, status, error];
}

/// Who owes whom, app-wide: the contact picker, the debt form and the debts
/// list all read this one list.
class DebtDirectoryCubit extends Cubit<DebtDirectoryState>
    with Clearable, SyncBacked<DebtDirectoryState> {
  DebtDirectoryCubit({required SyncCoordinator coordinator})
    : syncCoordinator = coordinator,
      super(const DebtDirectoryState()) {
    bindSync();
  }

  @override
  final SyncCoordinator syncCoordinator;

  @override
  SyncSet get syncSet => SyncSet.debtPeople;

  @override
  bool get syncLoading => state.status == DebtDirectoryStatus.loading;

  @override
  void markSyncLoading() => emit(
    DebtDirectoryState(
      people: state.people,
      status: DebtDirectoryStatus.loading,
    ),
  );

  @override
  void syncFailed(ApiException error) => emit(
    DebtDirectoryState(
      people: state.people,
      status: DebtDirectoryStatus.error,
      error: error,
    ),
  );

  @override
  void applySync(Map<String, dynamic> body) {
    emit(
      DebtDirectoryState(
        people: DebtPeoplePage.fromJson(body).items,
        status: DebtDirectoryStatus.loaded,
      ),
    );
  }

  @override
  void clear() => emit(const DebtDirectoryState());

  Future<void> loadIfNeeded() async {
    if (state.status == DebtDirectoryStatus.loaded ||
        state.status == DebtDirectoryStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() => loadSynced();

  PersonBalance? byKey(String key) {
    for (final p in state.people) {
      if (p.key == key) return p;
    }
    return null;
  }

  /// A write already returned the person's new balance: show it at once; the
  /// sync that follows confirms it.
  void applyBalance(PersonBalance b) {
    final known = state.people.any((p) => p.key == b.key);
    emit(
      DebtDirectoryState(
        people: [
          if (!known) b,
          for (final p in state.people)
            if (p.key == b.key) b else p,
        ],
        status: state.status,
      ),
    );
  }
}
