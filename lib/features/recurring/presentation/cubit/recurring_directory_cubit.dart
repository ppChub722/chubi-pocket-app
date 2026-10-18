import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/sync_backed.dart';
import '../../../../core/data/sync_coordinator.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../data/recurring_link_repository.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_summary.dart';

enum RecurringDirectoryStatus { initial, loading, loaded, error }

class RecurringDirectoryState extends Equatable {
  const RecurringDirectoryState({
    this.rules = const [],
    this.summary,
    this.status = RecurringDirectoryStatus.initial,
    this.error,
  });

  /// Every recurring setting, whatever its status, in the server's order.
  final List<Recurring> rules;
  final RecurringSummary? summary;
  final RecurringDirectoryStatus status;
  final ApiException? error;

  int get currentCount =>
      rules.where((r) => r.status != RecurringStatus.archived).length;
  int get archivedCount =>
      rules.where((r) => r.status == RecurringStatus.archived).length;

  @override
  List<Object?> get props => [rules, summary, status, error];
}

/// The recurring settings the picker and the recurring page read.
class RecurringDirectoryCubit extends Cubit<RecurringDirectoryState>
    with Clearable, SyncBacked<RecurringDirectoryState> {
  RecurringDirectoryCubit({required SyncCoordinator coordinator})
    : syncCoordinator = coordinator,
      super(const RecurringDirectoryState()) {
    bindSync();
  }

  @override
  final SyncCoordinator syncCoordinator;

  @override
  SyncSet get syncSet => SyncSet.recurring;

  @override
  bool get syncLoading => state.status == RecurringDirectoryStatus.loading;

  @override
  void markSyncLoading() => emit(
    RecurringDirectoryState(
      rules: state.rules,
      summary: state.summary,
      status: RecurringDirectoryStatus.loading,
    ),
  );

  @override
  void syncFailed(ApiException error) => emit(
    RecurringDirectoryState(
      rules: state.rules,
      summary: state.summary,
      status: RecurringDirectoryStatus.error,
      error: error,
    ),
  );

  @override
  void applySync(Map<String, dynamic> body) {
    emit(
      RecurringDirectoryState(
        rules: [
          for (final r in (body['data'] as List? ?? const []))
            Recurring.fromJson(r as Map<String, dynamic>),
        ],
        summary: RecurringSummary.fromJson(body['summary']),
        status: RecurringDirectoryStatus.loaded,
      ),
    );
  }

  @override
  void clear() => emit(const RecurringDirectoryState());

  Future<void> loadIfNeeded() async {
    if (state.status == RecurringDirectoryStatus.loaded ||
        state.status == RecurringDirectoryStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() => loadSynced();

  /// What `GET /recurring?for_type=…` answers: active settings of [type] that
  /// have an occurrence to link, the likely ones (same category, or an amount
  /// within 5%) first.
  List<LinkCandidate> candidates(
    TransactionType type, {
    String? categoryId,
    double? amount,
  }) {
    bool likely(Recurring r) {
      if (categoryId != null && r.category?.id == categoryId) return true;
      final a = r.amount;
      return amount != null &&
          amount > 0 &&
          a != null &&
          a > 0 &&
          (a - amount).abs() <= amount * 0.05 + 0.004;
    }

    final rows = <LinkCandidate>[
      for (final r in state.rules)
        if (r.status == RecurringStatus.active &&
            r.type == type &&
            r.currentOccurrence != null)
          LinkCandidate(
            likely: likely(r),
            setting: r,
            occurrence: LinkOccurrence(
              itemId: r.currentOccurrence!.itemId,
              date: r.currentOccurrence!.date,
              daysUntil: r.currentOccurrence!.daysUntil,
              status: switch (r.currentOccurrence!.status) {
                OccurrenceState.notCreated => 'not_created',
                final s => s.name,
              },
              amount: r.currentOccurrence!.amount,
            ),
          ),
    ];
    return [
      ...rows.where((c) => c.likely),
      ...rows.where((c) => !c.likely),
    ].take(100).toList();
  }
}
