import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/saving_goals_repository.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goals_overview.dart';

enum SavingGoalsStatus { initial, loading, loaded, error }

/// The list page's filter chips.
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
    this.status = SavingGoalsStatus.initial,
    this.error,
  });

  final SavingGoalsOverview overview;
  final SavingGoalsFilter filter;
  final SavingGoalsStatus status;
  final ApiException? error;

  List<SavingGoal> get goals => overview.goals;

  SavingGoalsState copyWith({
    SavingGoalsOverview? overview,
    SavingGoalsFilter? filter,
    SavingGoalsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) => SavingGoalsState(
    overview: overview ?? this.overview,
    filter: filter ?? this.filter,
    status: status ?? this.status,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [overview, filter, status, error];
}

/// The list page's state: ONE call per open (`GET /saving-goals?status=`).
/// Other cubits never patch it; a page that changed savings calls [markStale]
/// and the list reloads on its next open (the goal page lives in
/// `SavingGoalCubit`). Home listens to `goals` to refresh its tile.
class SavingGoalsCubit extends Cubit<SavingGoalsState> with Clearable {
  SavingGoalsCubit({required SavingGoalsRepository repository})
    : _repo = repository,
      super(const SavingGoalsState());

  final SavingGoalsRepository _repo;
  bool _stale = false;

  @override
  void clear() => emit(const SavingGoalsState());

  /// The list changed elsewhere: reload on the next [loadIfNeeded].
  void markStale() => _stale = true;

  Future<void> loadIfNeeded() {
    final fresh = state.status == SavingGoalsStatus.loaded && !_stale;
    if (fresh || state.status == SavingGoalsStatus.loading) {
      return Future.value();
    }
    return load();
  }

  /// Switching chip = re-opening the page with another status.
  Future<void> setFilter(SavingGoalsFilter filter) {
    emit(state.copyWith(filter: filter));
    return load();
  }

  Future<void> load() async {
    _stale = false;
    emit(state.copyWith(status: SavingGoalsStatus.loading, clearError: true));
    try {
      final overview = await _repo.list(status: state.filter.query);
      emit(
        state.copyWith(
          overview: overview,
          status: SavingGoalsStatus.loaded,
          clearError: true,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: SavingGoalsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }
}
