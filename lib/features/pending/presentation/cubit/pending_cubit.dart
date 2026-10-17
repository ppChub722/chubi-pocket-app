import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/pending_repository.dart';
import '../../domain/pending_transaction.dart';

enum PendingStatus { initial, loading, loaded, error }

class PendingState extends Equatable {
  const PendingState({
    this.items = const [],
    this.status = PendingStatus.initial,
    this.error,
    this.knownTotal,
    this.summary,
  });

  final List<PendingTransaction> items;

  /// The server's numbers from the last answer (load, submit, discard); the
  /// chips read them as they are, never counted from the rows.
  final PendingSummary? summary;

  final PendingStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  final int? knownTotal;

  int get count => knownTotal != null && knownTotal! > items.length
      ? knownTotal!
      : items.length;

  PendingState copyWith({
    List<PendingTransaction>? items,
    PendingStatus? status,
    ApiException? error,
    PendingSummary? summary,
  }) => PendingState(
    items: items ?? this.items,
    status: status ?? this.status,
    error: error,
    summary: summary ?? this.summary,
  );

  @override
  List<Object?> get props => [items, status, error, knownTotal, summary];
}

class PendingCubit extends Cubit<PendingState> with Clearable {
  PendingCubit({required PendingRepository repository})
    : _repo = repository,
      super(const PendingState());

  final PendingRepository _repo;

  @override
  void clear() => emit(const PendingState());

  Future<void> loadIfNeeded() async {
    if (state.status == PendingStatus.initial) await load();
  }

  /// The dashboard's drafts total, for the badge, without loading the list.
  void setKnownTotal(int total) {
    if (state.status != PendingStatus.initial || state.knownTotal == total) {
      return;
    }
    emit(PendingState(knownTotal: total));
  }

  Future<void> load() async {
    emit(state.copyWith(status: PendingStatus.loading));
    try {
      final r = await _repo.list();
      emit(
        PendingState(
          items: r.items,
          status: PendingStatus.loaded,
          summary: r.summary,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: PendingStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<List<PendingTransaction>> add(List<PendingDraft> drafts) async {
    final r = await _repo.create(drafts);
    emit(
      state.copyWith(items: [...r.items, ...state.items], summary: r.summary),
    );
    return r.items;
  }

  Future<PendingTransaction> updateDraft(String id, PendingDraft draft) async {
    final r = await _repo.update(id, draft);
    emit(
      state.copyWith(
        items: [for (final p in state.items) p.id == id ? r.draft : p],
        summary: r.summary,
      ),
    );
    return r.draft;
  }

  Future<void> discard(String id) async {
    final r = await _repo.delete(id);
    _drop({id, ...r.discarded, ...r.skipped}, r.summary);
  }

  Future<void> discardMany(List<String> ids) async {
    final r = await _repo.discard(ids);
    _drop({...r.discarded, ...r.skipped}, r.summary);
  }

  void _drop(Set<String> ids, PendingSummary? summary) => emit(
    state.copyWith(
      items: state.items.where((p) => !ids.contains(p.id)).toList(),
      summary: summary,
    ),
  );

  Future<PendingSubmitResult> submit(List<String> ids) async =>
      _applySubmit(await _repo.submit(ids));

  Future<PendingSubmitResult> submitReady() async =>
      _applySubmit(await _repo.submitReady());

  Future<PendingSubmitResult> submitOne(String id) async =>
      _applySubmit(await _repo.submitOne(id));

  PendingSubmitResult _applySubmit(PendingSubmitResult result) {
    final done = result.submitted.toSet();
    final gone = {
      for (final id in result.failed.keys)
        if (!result.failedDrafts.containsKey(id)) id,
    };
    emit(
      state.copyWith(
        items: [
          for (final p in state.items)
            if (!done.contains(p.id) && !gone.contains(p.id))
              result.failedDrafts[p.id] ?? p,
        ],
        summary: result.summary,
      ),
    );
    return result;
  }
}
