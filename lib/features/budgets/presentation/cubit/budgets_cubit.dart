import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/budgets_repository.dart';
import '../../domain/budget.dart';
import '../../domain/budget_overview.dart';
import '../../domain/budget_period.dart';
import '../../domain/budget_scope.dart';

class BudgetsState extends Equatable {
  const BudgetsState({
    this.budgets = const [],
    this.status = BudgetsStatus.initial,
    this.error,
  });

  final List<Budget> budgets;
  final BudgetsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  BudgetsState copyWith({
    List<Budget>? budgets,
    BudgetsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) {
    return BudgetsState(
      budgets: budgets ?? this.budgets,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [budgets, status, error];
}

enum BudgetsStatus { initial, loading, loaded, error }

/// Budgets store backed by [BudgetsRepository].
///
/// The cached list defaults to user-scope active budgets — the standalone
/// `/budgets` page only renders user-scope. Project-scope budgets render
/// inside the project detail page (Phase 1c) and fetch on demand without
/// going through this cubit.
///
/// Mutators re-throw [ApiException]; the calling form / detail page
/// surfaces the message via snackbar.
class BudgetsCubit extends Cubit<BudgetsState> with Clearable {
  BudgetsCubit({required BudgetsRepository repository})
    : _repo = repository,
      super(const BudgetsState());

  final BudgetsRepository _repo;

  @override
  void clear() => emit(const BudgetsState());

  Future<void> loadIfNeeded() async {
    if (state.status == BudgetsStatus.loaded ||
        state.status == BudgetsStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: BudgetsStatus.loading, clearError: true));
    try {
      final list = await _repo.list(scope: BudgetScope.user);
      emit(
        state.copyWith(
          budgets: list,
          status: BudgetsStatus.loaded,
          clearError: true,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: BudgetsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<void> add(Budget draft) async {
    final created = await _repo.create(draft);
    emit(state.copyWith(budgets: [...state.budgets, created]));
  }

  Future<void> update(Budget budget) async {
    final updated = await _repo.update(budget);
    emit(
      state.copyWith(
        budgets: [
          for (final b in state.budgets)
            if (b.id == updated.id) updated else b,
        ],
      ),
    );
  }

  Future<void> archive(String id) async {
    await _repo.archive(id);
    emit(
      state.copyWith(budgets: state.budgets.where((b) => b.id != id).toList()),
    );
  }

  Future<void> restore(String id) async {
    final restored = await _repo.restore(id);
    emit(state.copyWith(budgets: [...state.budgets, restored]));
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    emit(
      state.copyWith(budgets: state.budgets.where((b) => b.id != id).toList()),
    );
  }

  /// Overview summary (spec §3.7). Not cached — recomputed on demand
  /// from the list page header / dashboard widget.
  Future<BudgetOverview> overview({
    BudgetPeriod period = BudgetPeriod.monthly,
    BudgetScope scope = BudgetScope.user,
    String? projectId,
  }) {
    return _repo.overview(period: period, scope: scope, projectId: projectId);
  }

  Budget? byId(String id) {
    for (final b in state.budgets) {
      if (b.id == id) return b;
    }
    return null;
  }
}
