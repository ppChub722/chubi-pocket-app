import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

/// State for [TransactionsCubit].
///
/// One cache for the user's whole book; consumers filter via
/// [TransactionsCubit.forAccount] etc. Pagination metadata is kept on
/// the state so [loadMore] can ask for the next page without callers
/// tracking it.
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

  /// Last-loaded page index. 0 = nothing loaded yet.
  final int page;
  final int totalPages;

  /// Bumped by every successful write (add / update / tags / remove) —
  /// never by loads. Screens that aggregate the book (dashboard) listen
  /// for it to know their totals went stale.
  final int revision;

  /// A [TransactionsCubit.loadMore] page fetch is in flight. Separate from
  /// [status] so a filter refetch / pull-to-refresh (status `loading`)
  /// doesn't read as "loading the next page".
  final bool loadingMore;

  /// What the whole filtered set adds up to (every page) — the summary
  /// card. Null when the server doesn't send it.
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

/// Backing store for transaction screens. Mutations round-trip through
/// the API and are reflected via **surgical updates** — single-row
/// mutations replace one row in state; transfer mutations replace two
/// (matched by id). No full reload after a write.
///
/// A row only lands in the list when it matches the list's filters, at
/// its sorted place (owner 2026-10-10: a new expense showed under a
/// รายรับ filter; a back-dated one opened a new day at the top). When a
/// filter can't be judged here (search, tags, sub-categories) the list
/// re-fetches instead.
///
/// Several lists can be alive at once — the app's own, a wallet's รายการ
/// tab, the dashboard drill-down — each with its own cubit. A write
/// through any of them refreshes the others ([_live]); a write made
/// elsewhere (pending submit, debt settle, adjust balance) calls
/// [bookChanged].
class TransactionsCubit extends Cubit<TransactionsState> with Clearable {
  TransactionsCubit({required TransactionsRepository repository})
    : _repo = repository,
      super(const TransactionsState()) {
    _live.add(this);
  }

  final TransactionsRepository _repo;

  /// Every transactions list that's alive right now.
  static final Set<TransactionsCubit> _live = {};

  /// The book changed outside these cubits (a server-side write: pending
  /// submit, debt settle, copy-to-book, adjust balance, …) — every live
  /// list re-fetches, keeping its own filters and sort.
  static Future<void> bookChanged() =>
      Future.wait([for (final c in _live.toList()) c.refresh()]);

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

  /// Last-used filter / sort, reused by [loadMore].
  _ListQuery _last = const _ListQuery();

  /// Bumped per [load]; a response for an older load is dropped (search
  /// typing fires loads faster than they return).
  int _seq = 0;

  /// Fetches page 1 with the supplied filters, replacing the cache.
  /// Use this when the user changes filter / sort.
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
      sort: sort,
      perPage: perPage,
    );
    final seq = ++_seq;

    // A refetch supersedes any in-flight page (its response is dropped).
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

  /// Re-fetches page 1 with the **current** filters and sort — after a
  /// write the list should show, without resetting what the user picked
  /// (a bare [load] means all-time, no filters, while the chips still say
  /// "เดือนนี้"). Quiet: the rows stay on screen while it runs, and a
  /// failure keeps them. Does nothing before the first load.
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
    } catch (_) {
      // Keep what's on screen; the next pull / load tries again.
    }
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
        page: page,
        perPage: f.perPage,
        sort: f.sort,
      );

  /// Loads page 1 only when nothing's loaded yet. Page entry points
  /// (e.g. transactions list, account detail) call this from initState
  /// without paying for a refetch on every navigation.
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

  /// Appends the next page using the last-used filters/sort.
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

  /// Creates a transaction (or transfer pair) in ONE call — tags and splits
  /// ride in the body (API v2). The returned rows go into the cache where the
  /// list's filters put them; the result's `accountBalances` are for
  /// [AccountsCubit.patchBalances]. Re-throws [ApiException].
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
    // Only where the list's filters and sort put it (see [_place]).
    _emitWrite(state.copyWith(transactions: _place(result.rows)));
    return result;
  }

  /// Edits a transaction in ONE call. [tagIds] (when not null) replaces the
  /// tag set. Returns the rows + balances after the write.
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
    // Moved to a future date: it's an upcoming item now, not a transaction.
    if (result.isUpcoming) {
      dropRow(id);
      return result;
    }
    // An edit can move the row (new date / amount) or take it out of the
    // filters (new type / wallet / category).
    _emitWrite(state.copyWith(transactions: _place(result.rows)));
    return result;
  }

  /// Replaces the tags of [transactionId] with [tagIds] (one `PUT`); the
  /// row in the response goes into the cache.
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
    // Tags can take it in / out of a tag filter.
    _emitWrite(state.copyWith(transactions: _place([fresh])));
  }

  /// Deletes a transaction. For transfers, the BE cascades to the paired
  /// row; we drop both from the cache by `transfer_group_id`. Returns the
  /// wallets' balances after the delete. [alsoDeleteLink]: see
  /// [TransactionsRepository.delete].
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

  /// A row the server deleted through another record (a debt entry's wallet
  /// side goes with the entry): out of the cache — no call — and the other
  /// live lists re-read.
  void dropRow(String id) {
    if (isClosed) return;
    _emitWrite(
      state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      ),
    );
  }

  // ── Read helpers ──────────────────────────────────────────────────

  Transaction? byId(String id) {
    for (final t in state.transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Re-fetches one row in place (the detail page's pull to refresh, its
  /// split people) — a full [load] would re-run the list's filters, which
  /// may not include this row. Re-throws [ApiException].
  ///
  /// A read: a plain emit, no [refresh] — that would put page 1's list rows
  /// (no `splits`) straight back over the row just fetched. [afterWrite]:
  /// the row changed on the server (its splits were saved), so this goes
  /// the write path and the other lists re-fetch too.
  Future<Transaction> refreshOne(String id, {bool afterWrite = false}) async {
    final fresh = await _repo.get(id);
    if (isClosed) return fresh;
    patchRow(fresh, afterWrite: afterWrite);
    return fresh;
  }

  /// Puts a row the server just returned (a write response, a read) into the
  /// cache without another call: replaced in place when this list holds it,
  /// otherwise placed only if the list's filters want it. [afterWrite]: the
  /// row changed on the server, so the other live lists re-fetch too.
  void patchRow(Transaction fresh, {bool afterWrite = false}) {
    if (isClosed) return;
    final id = fresh.id;
    final known = state.transactions.any((t) => t.id == id);
    final next = state.copyWith(
      // A row this list doesn't hold (opened from elsewhere) is placed
      // only if the list's filters want it.
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

  /// Server returns transactions in date_desc order; this is just a
  /// view filter, not a re-sort.
  List<Transaction> forAccount(String accountId) =>
      state.transactions.where((t) => t.accountId == accountId).toList();

  // ── Internal ──────────────────────────────────────────────────────

  /// Emits a post-write state and bumps [TransactionsState.revision]; the
  /// other live lists re-fetch (a create from the + sheet shows up in the
  /// wallet's รายการ tab too). A list whose filters [_place] can't judge
  /// re-fetches itself.
  void _emitWrite(TransactionsState next) {
    emit(next.copyWith(revision: state.revision + 1));
    // Totals (summary card) and filters this list can't judge need the
    // server.
    if (!_last.judgeable || state.totals != null) unawaited(refresh());
    for (final other in _live.toList()) {
      if (other != this) unawaited(other.refresh());
    }
  }

  /// [state]'s rows with [rows] put where this list's filters and sort
  /// want them: an old copy is dropped; a row the filters exclude stays
  /// out; one sorting past the last loaded row waits for its page.
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

  /// [incoming] with the cached rows' `splits` carried over: list rows and
  /// write results come without the people (only GET /:id has them), so a
  /// row whose split_count didn't change keeps the ones already fetched.
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

  /// Replaces existing rows whose id matches one of [updates]; rows
  /// not in [updates] are preserved as-is. Order preserved.
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

/// The filters + sort of the last [TransactionsCubit.load].
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

  /// The multi-select filters: OR inside a group (wallets / categories / tags
  /// with their "none" flags, types), AND between groups.
  final List<String> accountIds;
  final List<String> categoryIds;
  final Set<TransactionType> types;
  final bool noTags;
  final String sort;
  final int perPage;

  /// Whether [matches] can tell, here, if a row belongs: a search, tags
  /// or "with sub-categories" need the server.
  bool get judgeable =>
      (q == null || q!.trim().isEmpty) &&
      tagIds.isEmpty &&
      !noTags &&
      !(includeChildren && (categoryId != null || categoryIds.isNotEmpty));

  /// [t] passes this query's filters (only meaningful when [judgeable]).
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
    return true;
  }

  /// < 0 when [a] comes before [b] in this query's sort. A new row goes
  /// first among equals for the newest-first / largest-first sorts (it's
  /// the latest of its day) and last for the oldest-first ones.
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
