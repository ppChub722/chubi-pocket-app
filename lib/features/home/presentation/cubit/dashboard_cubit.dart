import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data,
    this.month,
    this.error,
  });

  final DashboardStatus status;

  /// Last good payload — kept while reloading / on a failed refresh so
  /// the screen never blanks.
  final Dashboard? data;

  /// Selected month (first day); null = current month.
  final DateTime? month;
  final ApiException? error;
  String? get errorMessage => error?.message;

  @override
  List<Object?> get props => [status, data, month, error];
}

/// Home screen state — one `GET /dashboard` per load. The page reloads it
/// on pull-to-refresh, month change, and whenever transactions / wallets
/// change elsewhere in the app.
class DashboardCubit extends Cubit<DashboardState> with Clearable {
  DashboardCubit({required DashboardRepository repository})
    : _repo = repository,
      super(const DashboardState());

  final DashboardRepository _repo;

  @override
  void clear() {
    _stale?.cancel();
    _seq++;
    emit(const DashboardState());
  }

  /// First visit only — later visits keep the cached payload (listeners
  /// keep it fresh).
  Future<void> loadIfNeeded() async {
    if (state.status == DashboardStatus.initial) await load();
  }

  Timer? _stale;

  /// Bumped per [load] and on [clear]; stale responses are dropped.
  int _seq = 0;

  /// Something elsewhere changed (a budget, goal, debt, schedule) —
  /// reload once things settle. Bursts (a save that reloads several
  /// cubits) collapse into one request.
  void markStale() {
    _stale?.cancel();
    _stale = Timer(const Duration(milliseconds: 400), load);
  }

  @override
  Future<void> close() {
    _stale?.cancel();
    return super.close();
  }

  Future<void> load() async {
    final month = state.month;
    final seq = ++_seq;
    emit(
      DashboardState(
        status: DashboardStatus.loading,
        data: state.data,
        month: month,
      ),
    );
    try {
      final data = await _repo.get(month: month);
      // A newer load (month switch, refresh) or a logout wins.
      if (isClosed || seq != _seq) return;
      emit(
        DashboardState(
          status: DashboardStatus.loaded,
          data: data,
          month: month,
        ),
      );
    } catch (e, st) {
      if (isClosed || seq != _seq) return;
      emit(
        DashboardState(
          status: DashboardStatus.error,
          data: state.data,
          month: month,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  /// Moves the month-scoped blocks by [delta] months. Never past the
  /// current month — there's nothing to see in the future.
  Future<void> shiftMonth(int delta) async {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final base = state.month ?? state.data?.month ?? current;
    final next = DateTime(base.year, base.month + delta);
    if (next.isAfter(current)) return;
    emit(
      DashboardState(
        status: state.status,
        data: state.data,
        month: next == current ? null : next,
      ),
    );
    await load();
  }
}
