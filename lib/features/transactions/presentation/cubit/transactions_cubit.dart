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
    this.errorMessage,
    this.page = 0,
    this.totalPages = 0,
  });

  final List<Transaction> transactions;
  final TransactionsStatus status;
  final String? errorMessage;

  /// Last-loaded page index. 0 = nothing loaded yet.
  final int page;
  final int totalPages;

  bool get hasMore => page > 0 && page < totalPages;

  TransactionsState copyWith({
    List<Transaction>? transactions,
    TransactionsStatus? status,
    String? errorMessage,
    int? page,
    int? totalPages,
    bool clearError = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props =>
      [transactions, status, errorMessage, page, totalPages];
}

enum TransactionsStatus { initial, loading, loaded, error }

/// Backing store for transaction screens. Mutations round-trip through
/// the API and are reflected via **surgical updates** — single-row
/// mutations replace one row in state; transfer mutations replace two
/// (matched by id). No full reload after a write.
class TransactionsCubit extends Cubit<TransactionsState> with Clearable {
  TransactionsCubit({required TransactionsRepository repository})
      : _repo = repository,
        super(const TransactionsState());

  final TransactionsRepository _repo;

  @override
  void clear() {
    _lastAccountId = null;
    _lastCategoryId = null;
    _lastType = null;
    _lastFrom = null;
    _lastTo = null;
    _lastSort = 'date_desc';
    _lastPerPage = 20;
    emit(const TransactionsState());
  }

  /// Last-used filter / sort, reused by [loadMore].
  String? _lastAccountId;
  String? _lastCategoryId;
  TransactionsType? _lastType;
  String? _lastFrom;
  String? _lastTo;
  String _lastSort = 'date_desc';
  int _lastPerPage = 20;

  /// Fetches page 1 with the supplied filters, replacing the cache.
  /// Use this when the user changes filter / sort.
  Future<void> load({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? from,
    String? to,
    String sort = 'date_desc',
    int perPage = 20,
  }) async {
    _lastAccountId = accountId;
    _lastCategoryId = categoryId;
    _lastType = type == null ? null : TransactionsType._(type);
    _lastFrom = from;
    _lastTo = to;
    _lastSort = sort;
    _lastPerPage = perPage;

    emit(state.copyWith(
      status: TransactionsStatus.loading,
      clearError: true,
    ));
    try {
      final pageRes = await _repo.list(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        from: from,
        to: to,
        page: 1,
        perPage: perPage,
        sort: sort,
      );
      emit(state.copyWith(
        transactions: pageRes.transactions,
        status: TransactionsStatus.loaded,
        page: pageRes.page,
        totalPages: pageRes.totalPages,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: TransactionsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

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
    if (state.status == TransactionsStatus.loading) return;
    emit(state.copyWith(status: TransactionsStatus.loading, clearError: true));
    try {
      final pageRes = await _repo.list(
        accountId: _lastAccountId,
        categoryId: _lastCategoryId,
        type: _lastType?.value,
        from: _lastFrom,
        to: _lastTo,
        page: state.page + 1,
        perPage: _lastPerPage,
        sort: _lastSort,
      );
      emit(state.copyWith(
        transactions: [...state.transactions, ...pageRes.transactions],
        status: TransactionsStatus.loaded,
        page: pageRes.page,
        totalPages: pageRes.totalPages,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: TransactionsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  /// Creates a transaction (or transfer pair). Appends to the cache;
  /// re-throws [ApiException] so the form can show a snackbar.
  ///
  /// `tagIds`: optional list of tag ids to attach immediately after
  /// the create. Two HTTP calls under the hood (create then attach);
  /// no transaction-level "create with tags" endpoint exists in the
  /// spec. For transfers, tags are attached **only** to the OUT row
  /// — the user mentally tagged "the transfer", not "this side of
  /// the transfer".
  ///
  /// Returns the mutation result so callers can use the embedded
  /// `account_balance_after` to update the [AccountsCubit] surgically.
  Future<TransactionMutationResult> add({
    required TransactionType type,
    required String accountId,
    required double amount,
    required String date,
    String? categoryId,
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
      note: note,
      transferToAccountId: transferToAccountId,
      splits: splits,
    );
    // Attach tags if any. For transfers we attach only to the OUT row
    // (the one the user "owns" — the source account). The IN side is
    // a mirror entry for the destination account's ledger.
    if (tagIds.isNotEmpty) {
      final target = result.transfer != null
          ? result.transfer!.rows.firstWhere(
              (r) => r.signedAmount < 0,
              orElse: () => result.transfer!.rows.first,
            )
          : result.single!;
      try {
        final tags = await _repo.attachTags(
          transactionId: target.id,
          tagIds: tagIds,
        );
        // Patch the affected row's tags into our local copy of result
        // so the in-memory state reflects the attached tags.
        final patchedRow = target.copyWith(tags: tags);
        if (result.single != null) {
          emit(state.copyWith(
            transactions: [patchedRow, ...state.transactions],
          ));
          return TransactionMutationResult.single(patchedRow);
        }
        // Transfer — replace OUT row with the patched one.
        final newRows = [
          for (final r in result.transfer!.rows)
            if (r.id == target.id) patchedRow else r,
        ];
        emit(state.copyWith(
          transactions: [...newRows, ...state.transactions],
        ));
        return TransactionMutationResult.transfer(
          TransferResult(
            transferGroupId: result.transfer!.transferGroupId,
            rows: newRows,
          ),
        );
      } on ApiException {
        // Attach failed — the transaction itself is created. Surface
        // the rows unmodified; caller will see an error snackbar.
        emit(state.copyWith(
          transactions: [...result.rows, ...state.transactions],
        ));
        rethrow;
      }
    }
    // Insert the new row(s) at the front of the cache assuming
    // sort=date_desc and that the user just created today's transaction.
    // For older dates the order will be slightly off until next load.
    emit(state.copyWith(
      transactions: [...result.rows, ...state.transactions],
    ));
    return result;
  }

  Future<TransactionMutationResult> updateTransaction({
    required String id,
    double? amount,
    String? date,
    String? categoryId,
    bool clearCategory = false,
    String? note,
    bool clearNote = false,
  }) async {
    final result = await _repo.update(
      id: id,
      amount: amount,
      date: date,
      categoryId: categoryId,
      clearCategory: clearCategory,
      note: note,
      clearNote: clearNote,
    );
    final patched = _patch(state.transactions, result.rows);
    emit(state.copyWith(transactions: patched));
    return result;
  }

  /// Reconciles the tags attached to [transactionId] against [tagIds].
  /// Computes the diff, calls attach for newcomers and detach for the
  /// removals. Used by the edit form's Save flow when the user
  /// changes the chip selection.
  ///
  /// Patches the row in cubit state with the new tag list once the
  /// reconciliation succeeds.
  Future<void> setTags({
    required String transactionId,
    required List<String> tagIds,
  }) async {
    final current = byId(transactionId);
    if (current == null) return;
    final currentIds = current.tags.map((t) => t.id).toSet();
    final desired = tagIds.toSet();
    final toAttach = desired.difference(currentIds).toList();
    final toDetach = currentIds.difference(desired);

    if (toAttach.isEmpty && toDetach.isEmpty) return;

    // Apply removals first so a tag the user just unchecked doesn't
    // linger if the attach call fails partway.
    for (final id in toDetach) {
      await _repo.detachTag(transactionId: transactionId, tagId: id);
    }
    if (toAttach.isNotEmpty) {
      await _repo.attachTags(
        transactionId: transactionId,
        tagIds: toAttach,
      );
    }

    // Refresh the row by fetching it — simplest correct path; gives us
    // the BE's authoritative ordered tag list with full embedded
    // metadata (color/icon).
    final fresh = await _repo.get(transactionId);
    emit(state.copyWith(
      transactions: [
        for (final t in state.transactions)
          if (t.id == fresh.id) fresh else t,
      ],
    ));
  }

  /// Deletes a transaction. For transfers, the BE cascades to the
  /// paired row; we drop both from the cache by `transfer_group_id`.
  Future<void> remove(String id) async {
    final tx = byId(id);
    await _repo.delete(id);
    if (tx?.transferGroupId != null) {
      emit(state.copyWith(
        transactions: state.transactions
            .where((t) => t.transferGroupId != tx!.transferGroupId)
            .toList(),
      ));
    } else {
      emit(state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      ));
    }
  }

  // ── Read helpers ──────────────────────────────────────────────────

  Transaction? byId(String id) {
    for (final t in state.transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Server returns transactions in date_desc order; this is just a
  /// view filter, not a re-sort.
  List<Transaction> forAccount(String accountId) =>
      state.transactions.where((t) => t.accountId == accountId).toList();

  // ── Internal ──────────────────────────────────────────────────────

  /// Replaces existing rows whose id matches one of [updates]; rows
  /// not in [updates] are preserved as-is. Order preserved.
  List<Transaction> _patch(
      List<Transaction> existing, List<Transaction> updates) {
    if (updates.isEmpty) return existing;
    final byId = {for (final u in updates) u.id: u};
    return [
      for (final t in existing)
        if (byId.containsKey(t.id)) byId[t.id]! else t,
    ];
  }
}

/// Tiny holder so we can null-out the type filter cleanly across
/// load + loadMore. (Direct `TransactionType?` field would conflate
/// "no filter" with "filter not yet set".)
class TransactionsType {
  const TransactionsType._(this.value);
  final TransactionType value;
}
