import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/budgets_repository.dart';
import '../../domain/budget.dart';

class BudgetsState extends Equatable {
  const BudgetsState({
    this.budgets = const [],
    this.summary = const BudgetListSummary(),
    this.filter = BudgetFilter.active,
    this.sort = BudgetSort.risk,
    this.status = BudgetsStatus.initial,
    this.error,
  });

  /// Each budget at its current period (the BE's `listBudgets`).
  final List<Budget> budgets;
  final BudgetListSummary summary;
  final BudgetFilter filter;
  final BudgetSort sort;
  final BudgetsStatus status;
  final ApiException? error;

  String? get errorMessage => error?.message;

  BudgetsState copyWith({
    List<Budget>? budgets,
    BudgetListSummary? summary,
    BudgetFilter? filter,
    BudgetSort? sort,
    BudgetsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) => BudgetsState(
    budgets: budgets ?? this.budgets,
    summary: summary ?? this.summary,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    status: status ?? this.status,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [budgets, summary, filter, sort, status, error];
}

enum BudgetsStatus { initial, loading, loaded, error }

/// The budgets LIST page's state (spec 08 v2): one call per open, per filter
/// chip and per sort. Pages for one budget hold their own state from the
/// repository; a write there calls [markStale], a transaction write too
/// ([markStale] reloads once after a short pause, like the dashboard).
class BudgetsCubit extends Cubit<BudgetsState> with Clearable {
  BudgetsCubit({required BudgetsRepository repository})
    : _repo = repository,
      super(const BudgetsState());

  final BudgetsRepository _repo;
  Timer? _stale;

  /// Bumped per [load] and on [clear]; a stale response is dropped.
  int _request = 0;

  @override
  void clear() {
    _stale?.cancel();
    _request++;
    emit(const BudgetsState());
  }

  @override
  Future<void> close() {
    _stale?.cancel();
    return super.close();
  }

  /// A budget or a transaction changed: reload once, shortly (only when the
  /// list was ever opened).
  void markStale() {
    if (state.status == BudgetsStatus.initial) return;
    _stale?.cancel();
    _stale = Timer(const Duration(milliseconds: 400), load);
  }

  Future<void> load() async {
    _stale?.cancel();
    final request = ++_request;
    emit(state.copyWith(status: BudgetsStatus.loading, clearError: true));
    try {
      final list = await _repo.list(filter: state.filter, sort: state.sort);
      if (request != _request) return;
      emit(
        state.copyWith(
          budgets: list.budgets,
          summary: list.summary,
          status: BudgetsStatus.loaded,
          clearError: true,
        ),
      );
    } catch (e, st) {
      if (request != _request) return;
      emit(
        state.copyWith(
          status: BudgetsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  /// A chip: show another list (1 call; the old rows go at once).
  Future<void> setFilter(BudgetFilter filter) {
    if (filter == state.filter) return Future.value();
    emit(state.copyWith(filter: filter, budgets: const []));
    return load();
  }

  Future<void> setSort(BudgetSort sort) {
    if (sort == state.sort) return Future.value();
    emit(state.copyWith(sort: sort));
    return load();
  }
}
