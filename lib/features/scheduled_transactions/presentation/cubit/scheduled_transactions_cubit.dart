import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/scheduled_transactions_repository.dart';
import '../../domain/scheduled_history.dart';
import '../../domain/scheduled_transaction.dart';
import '../../domain/scheduled_upcoming.dart';

class ScheduledTransactionsState extends Equatable {
  const ScheduledTransactionsState({
    this.entries = const [],
    this.status = ScheduledTransactionsStatus.initial,
    this.errorMessage,
  });

  final List<ScheduledTransaction> entries;
  final ScheduledTransactionsStatus status;
  final String? errorMessage;

  ScheduledTransactionsState copyWith({
    List<ScheduledTransaction>? entries,
    ScheduledTransactionsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScheduledTransactionsState(
      entries: entries ?? this.entries,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [entries, status, errorMessage];
}

enum ScheduledTransactionsStatus { initial, loading, loaded, error }

/// Scheduled-transactions store backed by [ScheduledTransactionsRepository].
///
/// Mutators re-throw [ApiException]; lifecycle calls (`pause` / `resume` /
/// `cancel`) may surface `INVALID_TRANSITION` from the server when the
/// current state doesn't permit the move (spec §3.7).
///
/// `generateNow` returns the [GenerateNowResult] so the detail page can
/// snackbar a "View transaction" link; the cubit also patches the schedule
/// row in cache with the post-state so the UI advances immediately.
class ScheduledTransactionsCubit extends Cubit<ScheduledTransactionsState>
    with Clearable {
  ScheduledTransactionsCubit({
    required ScheduledTransactionsRepository repository,
  })  : _repo = repository,
        super(const ScheduledTransactionsState());

  final ScheduledTransactionsRepository _repo;

  @override
  void clear() => emit(const ScheduledTransactionsState());

  Future<void> loadIfNeeded() async {
    if (state.status == ScheduledTransactionsStatus.loaded ||
        state.status == ScheduledTransactionsStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() async {
    emit(state.copyWith(
      status: ScheduledTransactionsStatus.loading,
      clearError: true,
    ));
    try {
      final list = await _repo.list();
      emit(state.copyWith(
        entries: list,
        status: ScheduledTransactionsStatus.loaded,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: ScheduledTransactionsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> add(ScheduledTransaction draft) async {
    final created = await _repo.create(draft);
    emit(state.copyWith(entries: [...state.entries, created]));
  }

  Future<void> update(ScheduledTransaction entry) async {
    final updated = await _repo.update(entry);
    _replace(updated);
  }

  Future<void> pause(String id) async {
    final updated = await _repo.pause(id);
    _replace(updated);
  }

  Future<void> resume(String id) async {
    final updated = await _repo.resume(id);
    _replace(updated);
  }

  Future<void> cancel(String id) async {
    final updated = await _repo.cancel(id);
    // Cancelled is terminal; drop from the active cache.
    emit(state.copyWith(
      entries: state.entries.where((e) => e.id != updated.id).toList(),
    ));
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    ));
  }

  /// Manually trigger generation (spec §3.8). Phase 1c only — Phase 3+
  /// adds a real hourly cron. Patches the cached schedule row with the
  /// post-state (next billing date, remaining installments, status —
  /// which may flip to `completed` if this was the last installment).
  Future<GenerateNowResult> generateNow(String id) async {
    final result = await _repo.generateNow(id);
    final existing = byId(id);
    if (existing != null) {
      final patched = existing.copyWith(
        nextBillingDate: result.nextBillingDate,
        status: result.status,
        remainingInstallments: result.remainingInstallments,
      );
      // If the schedule has finished (completed), drop it from the
      // active cache; otherwise keep it with the patched fields.
      if (result.status.toJson() == 'active' ||
          result.status.toJson() == 'paused') {
        _replace(patched);
      } else {
        emit(state.copyWith(
          entries: state.entries.where((e) => e.id != id).toList(),
        ));
      }
    }
    return result;
  }

  Future<ScheduledHistory> history(String id) => _repo.history(id);

  Future<ScheduledUpcoming> upcoming({int days = 7}) =>
      _repo.upcoming(days: days);

  ScheduledTransaction? byId(String id) {
    for (final e in state.entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  void _replace(ScheduledTransaction updated) {
    emit(state.copyWith(entries: [
      for (final e in state.entries)
        if (e.id == updated.id) updated else e,
    ]));
  }
}
