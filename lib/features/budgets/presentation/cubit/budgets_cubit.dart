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
    this.query = '',
    this.health = BudgetHealth.all,
  });

  final String query;

  List<Budget> get visible {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return budgets;
    return [
      for (final b in budgets)
        if (b.name.toLowerCase().contains(q)) b,
    ];
  }

  final List<Budget> budgets;
  final BudgetListSummary summary;
  final BudgetFilter filter;
  final BudgetSort sort;

  final BudgetHealth health;
  final BudgetsStatus status;
  final ApiException? error;

  String? get errorMessage => error?.message;

  BudgetsState copyWith({
    List<Budget>? budgets,
    BudgetListSummary? summary,
    BudgetFilter? filter,
    BudgetSort? sort,
    BudgetHealth? health,
    BudgetsStatus? status,
    ApiException? error,
    String? query,
    bool clearError = false,
  }) => BudgetsState(
    query: query ?? this.query,
    budgets: budgets ?? this.budgets,
    summary: summary ?? this.summary,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    health: health ?? this.health,
    status: status ?? this.status,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    budgets,
    summary,
    filter,
    sort,
    health,
    status,
    error,
    query,
  ];
}

enum BudgetsStatus { initial, loading, loaded, error }

class BudgetsCubit extends Cubit<BudgetsState> with Clearable {
  BudgetsCubit({required BudgetsRepository repository})
    : _repo = repository,
      super(const BudgetsState());

  final BudgetsRepository _repo;
  Timer? _stale;

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
      final list = await _repo.list(
        filter: state.filter,
        sort: state.sort,
        health: state.health,
      );
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

  Future<void> setFilter(BudgetFilter filter) {
    if (filter == state.filter) return Future.value();
    emit(
      state.copyWith(
        filter: filter,
        health: BudgetHealth.all,
        budgets: const [],
      ),
    );
    return load();
  }

  Future<void> setHealth(BudgetHealth health) {
    final next = health == state.health ? BudgetHealth.all : health;
    emit(state.copyWith(health: next));
    return load();
  }

  void search(String query) {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
  }

  Future<void> setSort(BudgetSort sort) {
    if (sort == state.sort) return Future.value();
    emit(state.copyWith(sort: sort));
    return load();
  }
}
