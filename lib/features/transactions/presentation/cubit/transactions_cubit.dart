import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/data_changes.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

class TransactionsState extends Equatable {
  const TransactionsState({
    this.transactions = const [],
    this.status = TransactionsStatus.initial,
    this.error,
    this.page = 0,
    this.totalPages = 0,
    this.revision = 0,
    this.loadingMore = false,
    this.totals,
  });

  final List<Transaction> transactions;
  final TransactionsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  final int page;
  final int totalPages;

  /// Bumped by every successful write (add / update / tags / remove) — never by
  /// loads.
  final int revision;

  final bool loadingMore;

  final ListTotals? totals;

  bool get hasMore => page > 0 && page < totalPages;

  TransactionsState copyWith({
    List<Transaction>? transactions,
    TransactionsStatus? status,
    ApiException? error,
    int? page,
    int? totalPages,
    int? revision,
    bool? loadingMore,
    bool clearError = false,
    ListTotals? totals,
    bool clearTotals = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      revision: revision ?? this.revision,
      loadingMore: loadingMore ?? this.loadingMore,
      totals: clearTotals ? null : (totals ?? this.totals),
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    status,
    error,
    page,
    totalPages,
    revision,
    loadingMore,
    totals,
  ];
}

enum TransactionsStatus { initial, loading, loaded, error }

class TransactionsCubit extends Cubit<TransactionsState>
    with Clearable, RefreshOnDataChange<TransactionsState> {
  TransactionsCubit({required TransactionsRepository repository})
    : _repo = repository,
      super(const TransactionsState()) {
    _live.add(this);
    refreshOn({DataTable.transactions}, refresh);
  }

  final TransactionsRepository _repo;

  static final Set<TransactionsCubit> _live = {};

  @override
  Future<void> close() {
    _live.remove(this);
    return super.close();
  }

  @override
  void clear() {
    _last = const _ListQuery();
    _seq++;
    emit(const TransactionsState());
  }

  _ListQuery _last = const _ListQuery();

  int _seq = 0;

  Future<void> load({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? from,
    String? to,
    bool noWallet = false,
    String? q,
    List<String> tagIds = const [],
    bool includeChildren = false,
    bool uncategorized = false,
    List<String> accountIds = const [],
    List<String> categoryIds = const [],
    Set<TransactionType> types = const {},
    bool noTags = false,
    double? amountMin,
    double? amountMax,
    String sort = 'date_desc',
    int perPage = 20,
  }) async {
    _last = _ListQuery(
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      from: from,
      to: to,
      noWallet: noWallet,
      q: q,
      tagIds: tagIds,
      includeChildren: includeChildren,
      uncategorized: uncategorized,
      accountIds: accountIds,
      categoryIds: categoryIds,
      types: types,
      noTags: noTags,
      amountMin: amountMin,
      amountMax: amountMax,
      sort: sort,
      perPage: perPage,
    );
    final seq = ++_seq;

    emit(
      state.copyWith(
        status: TransactionsStatus.loading,
        loadingMore: false,
        clearError: true,
      ),
    );
    try {
      final pageRes = await _fetch(_last, page: 1);
      if (seq != _seq) return;
      emit(
        state.copyWith(
          transactions: pageRes.transactions,
          status: TransactionsStatus.loaded,
          page: pageRes.page,
          totals: pageRes.totals,
          clearTotals: pageRes.totals == null,
          totalPages: pageRes.totalPages,
        ),
      );
    } catch (e, st) {
      if (seq != _seq) return;
      emit(
        state.copyWith(
          status: TransactionsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (isClosed || state.status == TransactionsStatus.initial) return;
    final seq = ++_seq;
    try {
      final pageRes = await _fetch(_last, page: 1);
      if (seq != _seq || isClosed) return;
      emit(
        state.copyWith(
          transactions: _keepSplits(pageRes.transactions),
          status: TransactionsStatus.loaded,
          loadingMore: false,
          page: pageRes.page,
          totals: pageRes.totals,
          clearTotals: pageRes.totals == null,
          totalPages: pageRes.totalPages,
          clearError: true,
        ),
      );
    } catch (_) {}
  }

  Future<TransactionsPage> _fetch(_ListQuery f, {required int page}) =>
      _repo.list(
        accountId: f.accountId,
        categoryId: f.categoryId,
        type: f.type,
        from: f.from,
        to: f.to,
        noWallet: f.noWallet,
        q: f.q,
        tagIds: f.tagIds,
        includeChildren: f.includeChildren,
        uncategorized: f.uncategorized,
        accountIds: f.accountIds,
        categoryIds: f.categoryIds,
        types: f.types,
        noTags: f.noTags,
        amountMin: f.amountMin,
        amountMax: f.amountMax,
        page: page,
        perPage: f.perPage,
        sort: f.sort,
      );

  Future<void> loadIfNeeded({
    String? accountId,
    String? from,
    String? to,
  }) async {
    if (state.status == TransactionsStatus.loaded ||
        state.status == TransactionsStatus.loading) {
      return;
    }
    return load(accountId: accountId, from: from, to: to);
  }

  Future<void> loadMore() async {
    if (!state.hasMore) return;
    if (state.loadingMore || state.status == TransactionsStatus.loading) {
      return;
    }
    final seq = _seq;
    emit(state.copyWith(loadingMore: true, clearError: true));
    try {
      final pageRes = await _fetch(_last, page: state.page + 1);
      if (seq != _seq) return;
      emit(
        state.copyWith(
          transactions: [...state.transactions, ...pageRes.transactions],
          status: TransactionsStatus.loaded,
          loadingMore: false,
          page: pageRes.page,
          totalPages: pageRes.totalPages,
        ),
      );
    } catch (e, st) {
      if (seq != _seq) return;
      emit(
        state.copyWith(
          status: TransactionsStatus.error,
          loadingMore: false,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<TransactionWriteResult> add({
    required TransactionType type,
    String? accountId,
    required double amount,
    required String date,
    String? categoryId,
    String? description,
    String? note,
    String? transferToAccountId,
    List<String> tagIds = const [],
    List<Map<String, dynamic>>? splits,
  }) async {
    final result = await _repo.create(
      type: type,
      accountId: accountId,
      amount: amount,
      date: date,
      categoryId: categoryId,
      description: description,
      note: note,
      transferToAccountId: transferToAccountId,
      tagIds: tagIds,
      splits: splits,
    );
    _emitWrite(state.copyWith(transactions: _place(result.rows)));
    return result;
  }

  Future<TransactionWriteResult> updateTransaction({
    required String id,
    double? amount,
    String? date,
    String? categoryId,
    bool clearCategory = false,
    String? note,
    bool clearNote = false,
    String? description,
    bool clearDescription = false,
    String? accountId,
    bool clearAccount = false,
    String? transferToAccountId,
    List<String>? tagIds,
    bool? alsoUpdateLink,
  }) async {
    final result = await _repo.update(
      id: id,
      amount: amount,
      date: date,
      categoryId: categoryId,
      clearCategory: clearCategory,
      note: note,
      clearNote: clearNote,
      description: description,
      clearDescription: clearDescription,
      accountId: accountId,
      clearAccount: clearAccount,
      transferToAccountId: transferToAccountId,
      tagIds: tagIds,
      alsoUpdateLink: alsoUpdateLink,
    );
    if (result.isUpcoming) {
      dropRow(id);
      return result;
    }
    _emitWrite(state.copyWith(transactions: _place(result.rows)));
    return result;
  }

  Future<void> setTags({
    required String transactionId,
    required List<String> tagIds,
  }) async {
    final current = byId(transactionId);
    if (current != null) {
      final same =
          current.tags.length == tagIds.length &&
          current.tags.map((t) => t.id).toSet().containsAll(tagIds);
      if (same) return;
    }
    final fresh = await _repo.setTags(transactionId, tagIds);
    _emitWrite(state.copyWith(transactions: _place([fresh])));
  }

  Future<DeleteTransactionResult> remove(
    String id, {
    bool? alsoDeleteLink,
  }) async {
    final tx = byId(id);
    final result = await _repo.delete(id, alsoDeleteLink: alsoDeleteLink);
    if (tx?.transferGroupId != null) {
      _emitWrite(
        state.copyWith(
          transactions: state.transactions
              .where((t) => t.transferGroupId != tx!.transferGroupId)
              .toList(),
        ),
      );
    } else {
      _emitWrite(
        state.copyWith(
          transactions: state.transactions.where((t) => t.id != id).toList(),
        ),
      );
    }
    return result;
  }

  void dropRow(String id) {
    if (isClosed) return;
    _emitWrite(
      state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      ),
    );
  }

  Transaction? byId(String id) {
    for (final t in state.transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<Transaction> refreshOne(String id, {bool afterWrite = false}) async {
    final fresh = await _repo.get(id);
    if (isClosed) return fresh;
    patchRow(fresh, afterWrite: afterWrite);
    return fresh;
  }

  void patchRow(Transaction fresh, {bool afterWrite = false}) {
    if (isClosed) return;
    final id = fresh.id;
    final known = state.transactions.any((t) => t.id == id);
    final next = state.copyWith(
      transactions: known
          ? _patch(state.transactions, [fresh])
          : _place([fresh]),
    );
    if (afterWrite) {
      _emitWrite(next);
    } else {
      emit(next);
    }
  }

  List<Transaction> forAccount(String accountId) =>
      state.transactions.where((t) => t.accountId == accountId).toList();

  void _emitWrite(TransactionsState next) {
    emit(next.copyWith(revision: state.revision + 1));
    // Totals (summary card) and filters this list can't judge need the server.
    if (!_last.judgeable || state.totals != null) unawaited(refresh());
    for (final other in _live.toList()) {
      if (other != this) unawaited(other.refresh());
    }
  }

  List<Transaction> _place(List<Transaction> incoming) {
    final rows = _keepSplits(incoming);
    final ids = {for (final r in rows) r.id};
    final out = [
      for (final t in state.transactions)
        if (!ids.contains(t.id)) t,
    ];
    if (!_last.judgeable) return [...rows, ...out]; // refresh fixes it
    for (final r in rows) {
      if (!_last.matches(r)) continue;
      final at = out.indexWhere((t) => _last.compare(r, t) < 0);
      if (at >= 0) {
        out.insert(at, r);
      } else if (!state.hasMore) {
        out.add(r);
      }
    }
    return out;
  }

  List<Transaction> _keepSplits(List<Transaction> incoming) {
    final cached = {
      for (final t in state.transactions)
        if (t.splits.isNotEmpty) t.id: t,
    };
    if (cached.isEmpty) return incoming;
    return [
      for (final r in incoming)
        switch (cached[r.id]) {
          final old? when r.splits.isEmpty && r.splitCount == old.splitCount =>
            r.copyWith(splits: old.splits),
          _ => r,
        },
    ];
  }

  List<Transaction> _patch(
    List<Transaction> existing,
    List<Transaction> updates,
  ) {
    if (updates.isEmpty) return existing;
    final byId = {for (final u in updates) u.id: u};
    return [
      for (final t in existing)
        if (byId.containsKey(t.id)) byId[t.id]! else t,
    ];
  }
}

class _ListQuery {
  const _ListQuery({
    this.accountId,
    this.categoryId,
    this.type,
    this.from,
    this.to,
    this.noWallet = false,
    this.q,
    this.tagIds = const [],
    this.includeChildren = false,
    this.uncategorized = false,
    this.accountIds = const [],
    this.categoryIds = const [],
    this.types = const {},
    this.noTags = false,
    this.amountMin,
    this.amountMax,
    this.sort = 'date_desc',
    this.perPage = 20,
  });

  final String? accountId;
  final String? categoryId;
  final TransactionType? type;
  final String? from;
  final String? to;
  final bool noWallet;
  final String? q;
  final List<String> tagIds;
  final bool includeChildren;
  final bool uncategorized;

  final List<String> accountIds;
  final List<String> categoryIds;
  final Set<TransactionType> types;
  final bool noTags;

  final double? amountMin;
  final double? amountMax;
  final String sort;
  final int perPage;

  bool get judgeable =>
      (q == null || q!.trim().isEmpty) &&
      tagIds.isEmpty &&
      !noTags &&
      !(includeChildren && (categoryId != null || categoryIds.isNotEmpty));

  bool matches(Transaction t) {
    final day = t.date.length >= 10 ? t.date.substring(0, 10) : t.date;
    final wallets = [?accountId, ...accountIds];
    if (wallets.isNotEmpty || noWallet) {
      final ok =
          (t.accountId != null && wallets.contains(t.accountId)) ||
          (noWallet && t.accountId == null);
      if (!ok) return false;
    }
    final cats = [?categoryId, ...categoryIds];
    if (cats.isNotEmpty || uncategorized) {
      final ok =
          (t.categoryId != null && cats.contains(t.categoryId)) ||
          (uncategorized && t.categoryId == null);
      if (!ok) return false;
    }
    final kinds = {?type, ...types};
    if (kinds.isNotEmpty && !kinds.contains(t.type)) return false;
    if (from != null && day.compareTo(from!) < 0) return false;
    if (to != null && day.compareTo(to!) > 0) return false;
    if (amountMin != null && t.amount < amountMin!) return false;
    if (amountMax != null && t.amount > amountMax!) return false;
    return true;
  }

  int compare(Transaction a, Transaction b) {
    final byDate = a.date.compareTo(b.date);
    final byAmount = a.amount.compareTo(b.amount);
    return switch (sort) {
      'date_asc' => byDate == 0 ? 1 : byDate,
      'amount_desc' => byAmount == 0 ? -1 : -byAmount,
      'amount_asc' => byAmount == 0 ? 1 : byAmount,
      _ => byDate == 0 ? -1 : -byDate, // date_desc
    };
  }
}
