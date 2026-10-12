import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/saving_goals_repository.dart';
import '../../domain/saving_entry.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goals_overview.dart';

enum SavingPageStatus { loading, loaded, error }

class SavingPageState extends Equatable {
  const SavingPageState({
    this.status = SavingPageStatus.loading,
    this.detail,
    this.error,
    this.loadingMore = false,
  });

  final SavingPageStatus status;
  final SavingGoalDetail? detail;
  final ApiException? error;
  final bool loadingMore;

  SavingPageState copyWith({
    SavingPageStatus? status,
    SavingGoalDetail? detail,
    ApiException? error,
    bool? loadingMore,
    bool clearError = false,
  }) => SavingPageState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    error: clearError ? null : (error ?? this.error),
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [status, detail, error, loadingMore];
}

/// One goal page (or the spare bucket when [id] is
/// [SavingGoalsRepository.spareId]). Open = ONE call; every button = ONE
/// call, and its answer (`goal_page` / `spare_page`) replaces the page.
///
/// Write methods re-throw [ApiException] so the page can show the message and
/// keep the typed input.
class SavingGoalCubit extends Cubit<SavingPageState> {
  SavingGoalCubit({required SavingGoalsRepository repository, required this.id})
    : _repo = repository,
      super(const SavingPageState());

  final SavingGoalsRepository _repo;
  final String id;

  bool get isSpare => id == SavingGoalsRepository.spareId;

  Future<void> load() async {
    // Keep what is on screen during a reload (pull-to-refresh).
    emit(
      state.copyWith(
        status: state.detail == null ? SavingPageStatus.loading : null,
        clearError: true,
      ),
    );
    try {
      final detail = await _repo.detail(id);
      emit(state.copyWith(status: SavingPageStatus.loaded, detail: detail));
    } catch (e, st) {
      emit(
        state.copyWith(
          status: SavingPageStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<void> loadMoreEntries() async {
    final d = state.detail;
    if (d == null || !d.entries.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _repo.entries(bucketId: id, page: d.entries.page + 1);
      emit(
        state.copyWith(
          loadingMore: false,
          detail: d.copyWith(
            entries: SavingEntryPage(
              items: [...d.entries.items, ...next.items],
              page: next.page,
              totalPages: next.totalPages,
            ),
          ),
        ),
      );
    } catch (_) {
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// The write answered the page it was made from: show it, no re-read.
  void _apply(SavingWriteResult r) {
    final p = r.page;
    if (p != null) {
      emit(state.copyWith(status: SavingPageStatus.loaded, detail: p));
    }
  }

  /// Save / withdraw / move from this bucket.
  Future<SavingWriteResult> addEntry({
    required SavingEntryKind kind,
    required double amount,
    required String date,
    String? walletId,
    String? toGoalId,
    bool toSpare = false,
    List<SavingSplit>? splits,
    String? note,
  }) async {
    final r = await _repo.addEntry(
      kind: kind,
      amount: amount,
      date: date,
      goalId: isSpare ? null : id,
      walletId: walletId,
      toGoalId: toGoalId,
      toSpare: toSpare,
      splits: splits,
      note: note,
    );
    _apply(r);
    return r;
  }

  Future<SavingWriteResult> deleteEntry(String entryId) async {
    final r = await _repo.deleteEntry(entryId);
    _apply(r);
    return r;
  }

  Future<SavingWriteResult> closeGoal({required bool toWallets}) async {
    final r = await _repo.close(id, toWallets: toWallets);
    _apply(r);
    return r;
  }

  Future<void> update(SavingGoal goal) async {
    final d = await _repo.update(goal);
    emit(state.copyWith(status: SavingPageStatus.loaded, detail: d));
  }

  Future<void> archive() async {
    final d = await _repo.archive(id);
    emit(state.copyWith(status: SavingPageStatus.loaded, detail: d));
  }

  Future<void> restore() async {
    final d = await _repo.restore(id);
    emit(state.copyWith(status: SavingPageStatus.loaded, detail: d));
  }

  Future<void> delete() => _repo.delete(id);
}
