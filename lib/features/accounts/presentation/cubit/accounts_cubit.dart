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
    this.totals = const AccountTotals(),
    this.archivedCount = 0,
    this.totalsStale = false,
    this.status = AccountsStatus.initial,
    this.error,
  });

  final List<Account> accounts;

  /// The BE's summary over [accounts] (the accounts page's card).
  final AccountTotals totals;

  /// Archived wallets (the "ที่เก็บถาวร" row).
  final int archivedCount;

  /// A write moved a balance / the wallet set since [totals] was read: the
  /// accounts page re-reads once when it is next opened.
  final bool totalsStale;

  final AccountsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  AccountsState copyWith({
    List<Account>? accounts,
    AccountTotals? totals,
    int? archivedCount,
    bool? totalsStale,
    AccountsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      totals: totals ?? this.totals,
      archivedCount: archivedCount ?? this.archivedCount,
      totalsStale: totalsStale ?? this.totalsStale,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    accounts,
    totals,
    archivedCount,
    totalsStale,
    status,
    error,
  ];
}

enum AccountsStatus { initial, loading, loaded, error }

/// The accounts store backed by [AccountsRepository].
///
/// **No registration seed.** Per product decision, new users start with
/// zero accounts — the empty-state UX prompts them to create their first.
/// (Categories and tags are seeded; accounts are deliberately not.)
///
/// Mutators round-trip through the API, patch the state from the write's
/// response (never a list refetch) and re-throw [ApiException] on failure so
/// the form page can show a snackbar.
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

  /// Re-reads the list once if a write left the totals behind (the accounts
  /// page does this when it opens), without the loading state.
  Future<void> refreshIfStale() async {
    if (!state.totalsStale || state.status != AccountsStatus.loaded) return;
    try {
      final list = await _repo.list();
      emit(_fromList(list));
    } catch (_) {
      // Keep the cached rows; the next open tries again.
    }
  }

  AccountsState _fromList(AccountList list) => state.copyWith(
    accounts: list.data,
    totals: list.totals,
    archivedCount: list.archivedCount,
    totalsStale: false,
    status: AccountsStatus.loaded,
    clearError: true,
  );

  Future<void> load() async {
    emit(state.copyWith(status: AccountsStatus.loading, clearError: true));
    try {
      emit(_fromList(await _repo.list()));
    } catch (e, st) {
      emit(
        state.copyWith(
          status: AccountsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  /// Creates the wallet; returns it as the server made it (its id).
  Future<Account> add(Account draft) async {
    final created = await _repo.create(draft);
    emit(
      state.copyWith(accounts: [...state.accounts, created], totalsStale: true),
    );
    return created;
  }

  /// Saves the wallet's edits; returns the server's row. [currentBalance]:
  /// tracking turned back on — the balance it has now (one call; the BE
  /// books the adjustment). Totals change when tracking flips.
  Future<Account> update(Account account, {double? currentBalance}) async {
    final before = state.accounts.where((a) => a.id == account.id).firstOrNull;
    final updated = await _repo.update(account, currentBalance: currentBalance);
    _replace(updated);
    if (before != null && before.trackBalance != updated.trackBalance) {
      emit(state.copyWith(totalsStale: true));
    }
    return updated;
  }

  /// One wallet by id with its summary and members history — ONE call, any
  /// status (archived included). Not cached in the list.
  Future<AccountDetail> getDetail(String id) => _repo.getDetail(id);

  /// Archived wallets (for the "กระเป๋าที่เก็บถาวร" page).
  Future<List<Account>> listArchived() async =>
      (await _repo.list(status: 'archived')).data;

  /// Un-archive: the wallet comes back into the active list (its place by
  /// the caller's order). Returns it.
  Future<Account> restore(String id) async {
    final restored = await _repo.restore(id);
    final list = [
      for (final a in state.accounts)
        if (a.id != restored.id) a,
      restored,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    emit(
      state.copyWith(
        accounts: list,
        archivedCount: state.archivedCount > 0 ? state.archivedCount - 1 : 0,
        totalsStale: true,
      ),
    );
    return restored;
  }

  /// Archive (soft delete) — spec §3.10. The wallet leaves the active list
  /// and joins the archived count. Returns the archived wallet.
  Future<Account> remove(String id) async {
    final archived = await _repo.archive(id);
    emit(
      state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
        archivedCount: state.archivedCount + 1,
        totalsStale: true,
      ),
    );
    return archived;
  }

  /// Manual balance adjustment (spec §2.5): patches the wallet and every
  /// balance the write touched. Returns the result so the caller can show a
  /// "View" snackbar that links to the new transaction.
  Future<AdjustBalanceResult> adjustBalance({
    required String id,
    required double newBalance,
    String? description,
    String? note,
    String? date,
  }) async {
    final result = await _repo.adjustBalance(
      id: id,
      newBalance: newBalance,
      description: description,
      note: note,
      date: date,
    );
    _replace(result.account);
    patchBalances(result.accountBalances);
    return result;
  }

  /// Update the caller's own report scope on a shared wallet
  /// (spec §14/5). Re-throws [ApiException] (e.g. `SCOPE_NOT_ALLOWED`) for
  /// the caller to surface. Returns the wallet.
  Future<Account> setReportScope({
    required String accountId,
    required WalletReportScope scope,
  }) async {
    final updated = await _repo.setReportScope(
      accountId: accountId,
      scope: scope,
    );
    _replace(updated);
    return updated;
  }

  /// Remember one slip number on the wallet (owner). Returns the wallet.
  Future<Account> addIdentifier(
    String accountId,
    Map<String, dynamic> identifier,
  ) async {
    final updated = await _repo.addIdentifier(accountId, identifier);
    _replace(updated);
    return updated;
  }

  // ─── Shared wallets ─────────────────────────────────────────────────

  Future<MembersResult> inviteMember({
    required String accountId,
    String? contactId,
    String? email,
  }) async => _applyMembers(
    await _repo.inviteMember(
      accountId: accountId,
      contactId: contactId,
      email: email,
    ),
    accountId,
  );

  /// Leave (self), remove or cancel an invite. When the caller left, the
  /// wallet is dropped from the list (the result's `account` is null).
  Future<MembersResult> removeMember({
    required String accountId,
    required String memberId,
  }) async => _applyMembers(
    await _repo.removeMember(accountId: accountId, memberId: memberId),
    accountId,
  );

  Future<MembersResult> transferOwnership({
    required String accountId,
    required String newOwnerUserId,
  }) async => _applyMembers(
    await _repo.transferOwnership(
      accountId: accountId,
      newOwnerUserId: newOwnerUserId,
    ),
    accountId,
  );

  MembersResult _applyMembers(MembersResult r, String accountId) {
    final account = r.account;
    if (account == null) {
      // The caller left: the wallet is gone from their list.
      emit(
        state.copyWith(
          accounts: state.accounts.where((a) => a.id != accountId).toList(),
          totalsStale: true,
        ),
      );
    } else {
      _replace(account);
    }
    return r;
  }

  /// Accept a wallet invite: the joined wallet joins the list.
  Future<AcceptedInvite> acceptInvite(String notificationId) async {
    final joined = await _repo.acceptInvite(notificationId);
    upsert(joined.account);
    return joined;
  }

  // ─── Patching ───────────────────────────────────────────────────────

  Account? byId(String id) {
    for (final a in state.accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _replace(Account updated) {
    if (byId(updated.id) == null) return;
    emit(
      state.copyWith(
        accounts: [
          for (final a in state.accounts)
            if (a.id == updated.id) updated else a,
        ],
      ),
    );
  }

  /// Replace the row when the wallet is in the list (a fresher copy of it).
  void patch(Account account) => _replace(account);

  /// Replace the row, or add it (a wallet that just became active here).
  void upsert(Account account) {
    if (byId(account.id) != null) {
      _replace(account);
      return;
    }
    emit(
      state.copyWith(accounts: [...state.accounts, account], totalsStale: true),
    );
  }

  /// Surgical balance update used by [TransactionsCubit] consumers
  /// after a transaction mutation. Avoids a full `/v1/accounts` reload
  /// when the BE already told us the post-state via
  /// `account_balance_after` (spec §3.1).
  void patchBalance({required String accountId, required double newBalance}) {
    patchBalances({accountId: newBalance});
  }

  /// The wallets' new savings after a saving write (`wallets[].savings`), by
  /// account id. Wallets not in the map are left alone.
  void patchSavings(Map<String, WalletSavings> savings) {
    if (savings.isEmpty) return;
    emit(
      state.copyWith(
        accounts: [
          for (final a in state.accounts)
            if (savings.containsKey(a.id))
              a.copyWith(savings: savings[a.id])
            else
              a,
        ],
      ),
    );
  }

  /// [patchBalance] for several wallets at once (a transfer moves two): the
  /// post-write balances the BE returned (`account_balances`), by account
  /// id. Wallets not in the map are left alone.
  void patchBalances(Map<String, double> balances) {
    if (balances.isEmpty) return;
    emit(
      state.copyWith(
        accounts: [
          for (final a in state.accounts)
            if (balances.containsKey(a.id))
              a.copyWith(balance: balances[a.id])
            else
              a,
        ],
        totalsStale: true,
      ),
    );
  }

  /// Saves the caller's own wallet order ([ordered] = the full active
  /// list, top to bottom). Re-throws [ApiException]; state is untouched
  /// on failure. The response is the list in the new order.
  Future<void> saveOrder(List<Account> ordered) async {
    final fresh = await _repo.reorder([for (final a in ordered) a.id]);
    emit(_fromList(fresh));
  }
}
