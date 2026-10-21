import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/data_changes.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/saving_goals_repository.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goal_plan.dart';
import '../../domain/saving_goals_overview.dart';

enum SavingGoalsStatus { initial, loading, loaded, error }

enum SavingGoalsSort {
  /// Not a BE sort: the app orders the created list (see [SavingGoalsState.goals]).
  needFirst,
  created,
  deadline,
  progress,
  remaining,
  byName;

  String get query => switch (this) {
    byName => 'name',
    needFirst => 'created',
    _ => name,
  };
}

enum SavingGoalsFilter {
  active,
  completed,
  archived;

  String get query => name;
}

class SavingGoalsState extends Equatable {
  const SavingGoalsState({
    this.overview = const SavingGoalsOverview(),
    this.filter = SavingGoalsFilter.active,
    this.sort = SavingGoalsSort.needFirst,
    this.status = SavingGoalsStatus.initial,
    this.error,
    this.month,
  });

  final SavingGoalsOverview overview;
  final SavingGoalsFilter filter;
  final SavingGoalsSort sort;
  final SavingGoalsStatus status;
  final ApiException? error;

  /// The month whose plan the list shows (first day); null = the current one.
  final DateTime? month;

  /// Sorts on every call: read it once per build.
  List<SavingGoal> get goals => sort == SavingGoalsSort.needFirst
      ? sortedNeedFirst(overview.goals)
      : overview.goals;

  SavingGoalsState copyWith({
    SavingGoalsOverview? overview,
    SavingGoalsFilter? filter,
    SavingGoalsSort? sort,
    SavingGoalsStatus? status,
    ApiException? error,
    bool clearError = false,
    DateTime? month,
    bool clearMonth = false,
  }) => SavingGoalsState(
    overview: overview ?? this.overview,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    status: status ?? this.status,
    error: clearError ? null : (error ?? this.error),
    month: clearMonth ? null : (month ?? this.month),
  );

  @override
  List<Object?> get props => [overview, filter, sort, status, error, month];
}

class SavingGoalsCubit extends Cubit<SavingGoalsState>
    with Clearable, RefreshOnDataChange<SavingGoalsState> {
  SavingGoalsCubit({required SavingGoalsRepository repository})
    : _repo = repository,
      super(const SavingGoalsState()) {
    refreshOn({DataTable.savingGoals}, () async {
      if (state.status != SavingGoalsStatus.initial) await load(silent: true);
    });
  }

  final SavingGoalsRepository _repo;

  @override
  void clear() => emit(const SavingGoalsState());

  Future<void> loadIfNeeded() {
    if (state.status == SavingGoalsStatus.loaded ||
        state.status == SavingGoalsStatus.loading) {
      return Future.value();
    }
    return load();
  }

  Future<void> setFilter(SavingGoalsFilter filter) {
    emit(state.copyWith(filter: filter));
    return load();
  }

  Future<void> setSort(SavingGoalsSort sort) {
    emit(state.copyWith(sort: sort));
    return load();
  }

  /// Steps to another month's plan; the current month clears it.
  Future<void> setMonth(DateTime month) {
    final now = DateTime.now();
    final current = month.year == now.year && month.month == now.month;
    emit(
      current
          ? state.copyWith(clearMonth: true)
          : state.copyWith(month: DateTime(month.year, month.month)),
    );
    return load();
  }

  Future<void> resetMonth() async {
    if (state.month != null) await setMonth(DateTime.now());
  }

  Future<void> load({bool silent = false}) async {
    if (!silent || state.status != SavingGoalsStatus.loaded) {
      emit(state.copyWith(status: SavingGoalsStatus.loading, clearError: true));
    }
    try {
      final month = state.month;
      final overview = await _repo.list(
        status: state.filter.query,
        sort: state.sort.query,
        month: month == null
            ? null
            : '${month.year}-${month.month.toString().padLeft(2, '0')}',
      );
      // Leaving the page resets the month and reloads; the cubit may be
      // closed by the time the answer comes back.
      if (isClosed) return;
      emit(
        state.copyWith(
          overview: overview,
          status: SavingGoalsStatus.loaded,
          clearError: true,
        ),
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SavingGoalsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }
}
