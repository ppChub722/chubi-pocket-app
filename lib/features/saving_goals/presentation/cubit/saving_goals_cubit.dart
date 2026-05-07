import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/saving_goals_repository.dart';
import '../../domain/saving_allocation_summary.dart';
import '../../domain/saving_goal.dart';

/// State for [SavingGoalsCubit]. Mirrors the single-class-with-enum-status
/// shape used by [AccountsState] / [CategoriesState].
class SavingGoalsState extends Equatable {
  const SavingGoalsState({
    this.goals = const [],
    this.status = SavingGoalsStatus.initial,
    this.errorMessage,
  });

  final List<SavingGoal> goals;
  final SavingGoalsStatus status;
  final String? errorMessage;

  SavingGoalsState copyWith({
    List<SavingGoal>? goals,
    SavingGoalsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SavingGoalsState(
      goals: goals ?? this.goals,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [goals, status, errorMessage];
}

enum SavingGoalsStatus { initial, loading, loaded, error }

/// Saving goals store backed by [SavingGoalsRepository].
///
/// Mutators (add / update / archive / restore / remove) re-throw
/// [ApiException] so the calling page can show a snackbar. The
/// `ALLOCATION_EXCEEDED` rejection is surfaced verbatim from the API
/// `message` field — the user sees the same wording the BE chose.
///
/// Allocation summary lookups are NOT cached on the cubit — they're
/// fetched on demand from the form / detail page since they reflect a
/// computed cross-goal view that goes stale the moment any goal on the
/// account changes.
class SavingGoalsCubit extends Cubit<SavingGoalsState> with Clearable {
  SavingGoalsCubit({required SavingGoalsRepository repository})
      : _repo = repository,
        super(const SavingGoalsState());

  final SavingGoalsRepository _repo;

  @override
  void clear() => emit(const SavingGoalsState());

  Future<void> loadIfNeeded() async {
    if (state.status == SavingGoalsStatus.loaded ||
        state.status == SavingGoalsStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: SavingGoalsStatus.loading, clearError: true));
    try {
      final list = await _repo.list();
      emit(state.copyWith(
        goals: list,
        status: SavingGoalsStatus.loaded,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: SavingGoalsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> add(SavingGoal draft) async {
    final created = await _repo.create(draft);
    emit(state.copyWith(goals: [...state.goals, created]));
  }

  Future<void> update(SavingGoal goal) async {
    final updated = await _repo.update(goal);
    emit(state.copyWith(goals: [
      for (final g in state.goals)
        if (g.id == updated.id) updated else g,
    ]));
  }

  /// Archive (spec §3.6). The active list drops the archived row since
  /// `loadIfNeeded` only fetches active goals by default.
  Future<void> archive(String id) async {
    await _repo.archive(id);
    emit(state.copyWith(
      goals: state.goals.where((g) => g.id != id).toList(),
    ));
  }

  /// Restore (spec §3.6). The server may reject with
  /// `ALLOCATION_EXCEEDED` if the goal's stored `allocation_pct` plus
  /// the account's current sum would exceed 100% — re-thrown.
  Future<void> restore(String id) async {
    final restored = await _repo.restore(id);
    emit(state.copyWith(goals: [...state.goals, restored]));
  }

  /// Hard delete (spec §3.5). No cascades — account + transactions
  /// untouched.
  Future<void> remove(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(
      goals: state.goals.where((g) => g.id != id).toList(),
    ));
  }

  /// Per-account allocation pie (spec §3.7). Not cached — see class
  /// docs.
  Future<SavingAllocationSummary> allocationsFor(String accountId) {
    return _repo.allocationsFor(accountId);
  }

  SavingGoal? byId(String id) {
    for (final g in state.goals) {
      if (g.id == id) return g;
    }
    return null;
  }
}
