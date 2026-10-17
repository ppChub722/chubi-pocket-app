import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/accounts_repository.dart';
import '../../domain/account.dart';
import '../../domain/wallet_member.dart';

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

  final AccountTotals totals;

  final int archivedCount;

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

  Future<Account> add(Account draft) async {
    final created = await _repo.create(draft);
    emit(
      state.copyWith(accounts: [...state.accounts, created], totalsStale: true),
    );
    return created;
  }

  Future<Account> update(Account account, {double? currentBalance}) async {
    final before = state.accounts.where((a) => a.id == account.id).firstOrNull;
    final updated = await _repo.update(account, currentBalance: currentBalance);
    _replace(updated);
    if (before != null && before.trackBalance != updated.trackBalance) {
      emit(state.copyWith(totalsStale: true));
    }
    return updated;
  }

  Future<AccountDetail> getDetail(String id) => _repo.getDetail(id);

  Future<List<Account>> listArchived() async =>
      (await _repo.list(status: 'archived')).data;

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

  /// The confirm dialog's numbers (`include=delete_preview`); null when the
  /// caller can't delete this wallet.
  Future<AccountDeletePreview?> deletePreview(String id) =>
      _repo.deletePreview(id);

  Future<AccountDeletePreview> deleteForever(String id) async {
    final wasArchived = state.accounts.every((a) => a.id != id);
    final done = await _repo.delete(id);
    emit(
      state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
        archivedCount: wasArchived && state.archivedCount > 0
            ? state.archivedCount - 1
            : state.archivedCount,
        totalsStale: true,
      ),
    );
    return done;
  }

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

  Future<Account> addIdentifier(
    String accountId,
    Map<String, dynamic> identifier,
  ) async {
    final updated = await _repo.addIdentifier(accountId, identifier);
    _replace(updated);
    return updated;
  }

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

  Future<AcceptedInvite> acceptInvite(String notificationId) async {
    final joined = await _repo.acceptInvite(notificationId);
    upsert(joined.account);
    return joined;
  }

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

  void patch(Account account) => _replace(account);

  void upsert(Account account) {
    if (byId(account.id) != null) {
      _replace(account);
      return;
    }
    emit(
      state.copyWith(accounts: [...state.accounts, account], totalsStale: true),
    );
  }

  void patchBalance({required String accountId, required double newBalance}) {
    patchBalances({accountId: newBalance});
  }

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

  Future<void> saveOrder(List<Account> ordered) async {
    final fresh = await _repo.reorder([for (final a in ordered) a.id]);
    emit(_fromList(fresh));
  }
}
