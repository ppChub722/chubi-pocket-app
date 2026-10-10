import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/accounts_repository.dart';
import '../../domain/account.dart';
import '../../domain/wallet_member.dart';

/// State for [AccountsCubit]. See [CategoriesState] for rationale on the
/// single-class-with-enum-status shape.
class AccountsState extends Equatable {
  const AccountsState({
    this.accounts = const [],
    this.status = AccountsStatus.initial,
    this.error,
  });

  final List<Account> accounts;
  final AccountsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  AccountsState copyWith({
    List<Account>? accounts,
    AccountsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [accounts, status, error];
}

enum AccountsStatus { initial, loading, loaded, error }

/// The accounts store backed by [AccountsRepository].
///
/// **No registration seed.** Per product decision, new users start with
/// zero accounts — the empty-state UX prompts them to create their first.
/// (Categories and tags are seeded; accounts are deliberately not.)
///
/// Mutators round-trip through the API and re-throw [ApiException] on
/// failure so the form page can show a snackbar.
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
      emit(
        state.copyWith(
          accounts: list,
          status: AccountsStatus.loaded,
          clearError: true,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: AccountsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<void> add(Account draft) async {
    final created = await _repo.create(draft);
    emit(state.copyWith(accounts: [...state.accounts, created]));
  }

  Future<void> update(Account account) async {
    final updated = await _repo.update(account);
    emit(
      state.copyWith(
        accounts: [
          for (final a in state.accounts)
            if (a.id == updated.id) updated else a,
        ],
      ),
    );
  }

  /// Archived wallets (for the "กระเป๋าที่เก็บถาวร" page).
  Future<List<Account>> listArchived() => _repo.list(status: 'archived');

  Future<void> restore(String id) async {
    await _repo.restore(id);
    await load();
  }

  /// Archive (soft delete) — spec §3.10. The server flips status to
  /// 'archived'; locally we drop the row from the active list since
  /// `loadIfNeeded` only fetches active accounts by default.
  Future<void> remove(String id) async {
    await _repo.archive(id);
    emit(
      state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
      ),
    );
  }

  /// Manual balance adjustment (spec §2.5). Server creates an
  /// Adjustment transaction whose delta brings the account to
  /// [newBalance]. Returns the outcome so the caller can show a
  /// "View" snackbar that links to the new transaction.
  Future<AdjustBalanceOutcome> adjustBalance({
    required String id,
    required double newBalance,
    String? description,
    String? note,
    String? date,
  }) async {
    final outcome = await _repo.adjustBalance(
      id: id,
      newBalance: newBalance,
      description: description,
      note: note,
      date: date,
    );
    emit(
      state.copyWith(
        accounts: [
          for (final a in state.accounts)
            if (a.id == outcome.account.id) outcome.account else a,
        ],
      ),
    );
    return outcome;
  }

  /// Update the caller's own report scope on a shared wallet
  /// (spec §14/5). Round-trips `PUT /v1/accounts/:id/report-scope`, then
  /// patches the cached row so the settings UI reflects immediately.
  /// Re-throws [ApiException] (e.g. `SCOPE_NOT_ALLOWED`) for the caller
  /// to surface.
  Future<void> setReportScope({
    required String accountId,
    required WalletReportScope scope,
  }) async {
    await _repo.setReportScope(accountId: accountId, scope: scope);
    emit(
      state.copyWith(
        accounts: [
          for (final a in state.accounts)
            if (a.id == accountId) a.copyWith(myReportScope: scope) else a,
        ],
      ),
    );
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
  void patchBalance({required String accountId, required double newBalance}) {
    emit(
      state.copyWith(
        accounts: [
          for (final a in state.accounts)
            if (a.id == accountId) a.copyWith(balance: newBalance) else a,
        ],
      ),
    );
  }

  /// Saves the caller's own wallet order ([ordered] = the full active
  /// list, top to bottom). Re-throws [ApiException]; state is untouched
  /// on failure.
  Future<void> saveOrder(List<Account> ordered) async {
    final fresh = await _repo.reorder([for (final a in ordered) a.id]);
    emit(state.copyWith(accounts: fresh));
  }
}
