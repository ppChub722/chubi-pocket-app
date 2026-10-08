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
    this.errorMessage,
  });

  final List<PendingTransaction> items;
  final PendingStatus status;
  final String? errorMessage;

  int get count => items.length;

  PendingState copyWith({
    List<PendingTransaction>? items,
    PendingStatus? status,
    String? errorMessage,
  }) =>
      PendingState(
        items: items ?? this.items,
        status: status ?? this.status,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [items, status, errorMessage];
}

/// App-scoped drafts cache — the top-bar badge, the dashboard block and the
/// รอยืนยัน page all read it. Mutations re-throw [ApiException].
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

  Future<void> load() async {
    emit(state.copyWith(status: PendingStatus.loading));
    try {
      final items = await _repo.list();
      emit(PendingState(items: items, status: PendingStatus.loaded));
    } on ApiException catch (e) {
      emit(state.copyWith(status: PendingStatus.error, errorMessage: e.message));
    }
  }

  Future<List<PendingTransaction>> add(List<PendingDraft> drafts) async {
    final created = await _repo.create(drafts);
    emit(state.copyWith(items: [...created, ...state.items]));
    return created;
  }

  Future<PendingTransaction> updateDraft(String id, PendingDraft draft) async {
    final updated = await _repo.update(id, draft);
    emit(state.copyWith(items: [
      for (final p in state.items) p.id == id ? updated : p,
    ]));
    return updated;
  }

  Future<void> discard(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(items: state.items.where((p) => p.id != id).toList()));
  }

  /// Submits [ids]; the ones that went through leave the list, the failed
  /// ones stay with their reason.
  Future<PendingSubmitResult> submit(List<String> ids) async {
    final result = await _repo.submit(ids);
    final done = result.submitted.toSet();
    emit(state.copyWith(items: [
      for (final p in state.items)
        if (!done.contains(p.id))
          result.failed[p.id] == null
              ? p
              : PendingTransaction(
                  id: p.id,
                  source: p.source,
                  kind: p.kind,
                  draft: p.draft,
                  createdAt: p.createdAt,
                  sourceRef: p.sourceRef,
                  lastError: result.failed[p.id],
                ),
    ]));
    return result;
  }
}
