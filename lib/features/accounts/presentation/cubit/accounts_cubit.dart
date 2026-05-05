import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/accounts_repository.dart';
import '../../domain/account.dart';

/// State for [AccountsCubit]. See [CategoriesState] for rationale on the
/// single-class-with-enum-status shape.
class AccountsState extends Equatable {
  const AccountsState({
    this.accounts = const [],
    this.status = AccountsStatus.initial,
    this.errorMessage,
  });

  final List<Account> accounts;
  final AccountsStatus status;
  final String? errorMessage;

  AccountsState copyWith({
    List<Account>? accounts,
    AccountsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [accounts, status, errorMessage];
}

enum AccountsStatus { initial, loading, loaded, error }

/// Accounts store backed by [AccountsRepository].
///
/// **No registration seed.** Per product decision, new users start with
/// zero accounts — the empty-state UX prompts them to create their first.
/// (Categories and tags are seeded; accounts are deliberately not.)
///
/// Mutators round-trip through the API and re-throw [ApiException] on
/// failure so the form page can show a snackbar. Local reorder is
/// in-memory only for now — the BE has a `sort_order` column but no
/// reorder endpoint yet (spec §3.5 Phase 2).
class AccountsCubit extends Cubit<AccountsState> with Clearable {
  AccountsCubit({required AccountsRepository repository})
      : _repo = repository,
        super(const AccountsState());

  final AccountsRepository _repo;

  @override
  void clear() => emit(const AccountsState());

  Future<void> loadIfNeeded() async {
    if (state.status == AccountsStatus.loaded ||
        state.status == AccountsStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: AccountsStatus.loading, clearError: true));
    try {
      final list = await _repo.list();
      emit(state.copyWith(
        accounts: list,
        status: AccountsStatus.loaded,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AccountsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> add(Account draft) async {
    final created = await _repo.create(draft);
    emit(state.copyWith(accounts: [...state.accounts, created]));
  }

  Future<void> update(Account account) async {
    final updated = await _repo.update(account);
    emit(state.copyWith(accounts: [
      for (final a in state.accounts)
        if (a.id == updated.id) updated else a,
    ]));
  }

  /// Archive (soft delete) — spec §3.10. The server flips status to
  /// 'archived'; locally we drop the row from the active list since
  /// `loadIfNeeded` only fetches active accounts by default.
  Future<void> remove(String id) async {
    await _repo.archive(id);
    emit(state.copyWith(
      accounts: state.accounts.where((a) => a.id != id).toList(),
    ));
  }

  /// Manual balance adjustment (spec §2.5). Server creates an
  /// Adjustment transaction whose delta brings the account to
  /// [newBalance]. Returns the outcome so the caller can show a
  /// "View" snackbar that links to the new transaction.
  Future<AdjustBalanceOutcome> adjustBalance({
    required String id,
    required double newBalance,
    String? note,
    String? date,
  }) async {
    final outcome = await _repo.adjustBalance(
      id: id,
      newBalance: newBalance,
      note: note,
      date: date,
    );
    emit(state.copyWith(accounts: [
      for (final a in state.accounts)
        if (a.id == outcome.account.id) outcome.account else a,
    ]));
    return outcome;
  }

  Account? byId(String id) {
    for (final a in state.accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Surgical balance update used by [TransactionsCubit] consumers
  /// after a transaction mutation. Avoids a full `/v1/accounts` reload
  /// when the BE already told us the post-state via
  /// `account_balance_after` (spec §3.1).
  void patchBalance({
    required String accountId,
    required double newBalance,
  }) {
    emit(state.copyWith(accounts: [
      for (final a in state.accounts)
        if (a.id == accountId) a.copyWith(balance: newBalance) else a,
    ]));
  }

  /// Local-only reorder — the spec-§3.5 reorder endpoint isn't on the
  /// roadmap until Phase 2. Until then we shuffle the in-memory list so
  /// the user gets immediate feedback; on next [load] the server's
  /// stored order wins.
  void reorder(int oldIndex, int newIndex) {
    final list = [...state.accounts];
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = list.removeAt(oldIndex);
    list.insert(adjusted, item);
    emit(state.copyWith(accounts: list));
  }
}
