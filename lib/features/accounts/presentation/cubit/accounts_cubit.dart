import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/sync_backed.dart';
import '../../../../core/data/sync_coordinator.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/data/write_effects.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/accounts_repository.dart';
import '../../domain/account.dart';
import '../../domain/wallet_member.dart';

class AccountsState extends Equatable {
  const AccountsState({
    this.accounts = const [],
    this.archivedAccounts = const [],
    this.totals = const AccountTotals(),
    this.archivedCount = 0,
    this.status = AccountsStatus.initial,
    this.error,
  });

  /// The active wallets, in the caller's order (what the whole app reads).
  final List<Account> accounts;

  final List<Account> archivedAccounts;

  List<Account> get allAccounts => [...accounts, ...archivedAccounts];

  final AccountTotals totals;

  final int archivedCount;

  final AccountsStatus status;
  final ApiException? error;

  AccountsState copyWith({
    List<Account>? accounts,
    List<Account>? archivedAccounts,
    AccountTotals? totals,
    int? archivedCount,
    AccountsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      archivedAccounts: archivedAccounts ?? this.archivedAccounts,
      totals: totals ?? this.totals,
      archivedCount: archivedCount ?? this.archivedCount,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    accounts,
    archivedAccounts,
    totals,
    archivedCount,
    status,
    error,
  ];
}

enum AccountsStatus { initial, loading, loaded, error }

class AccountsCubit extends Cubit<AccountsState>
    with
        Clearable,
        SyncBacked<AccountsState>,
        ApplyWriteEffects<AccountsState> {
  AccountsCubit({
    required AccountsRepository repository,
    required SyncCoordinator coordinator,
  }) : _repo = repository,
       syncCoordinator = coordinator,
       super(const AccountsState()) {
    bindSync();
    // B2: every wallet a write moved, linked sides included.
    applyEffectsWith(
      (e) => patchBalances({
        for (final b in e.accountBalances)
          if (b['account_id'] is String && b['balance'] is num)
            b['account_id'] as String: (b['balance'] as num).toDouble(),
      }),
    );
  }

  final AccountsRepository _repo;

  @override
  final SyncCoordinator syncCoordinator;

  @override
  SyncSet get syncSet => SyncSet.accounts;

  @override
  bool get syncLoading => state.status == AccountsStatus.loading;

  @override
  void markSyncLoading() =>
      emit(state.copyWith(status: AccountsStatus.loading, clearError: true));

  @override
  void syncFailed(ApiException error) =>
      emit(state.copyWith(status: AccountsStatus.error, error: error));

  @override
  void applySync(Map<String, dynamic> body) {
    final list = AccountList.fromJson(body);
    emit(
      state.copyWith(
        accounts: [
          for (final a in list.data)
            if (!a.isArchived) a,
        ],
        archivedAccounts: [
          for (final a in list.data)
            if (a.isArchived) a,
        ],
        totals: list.totals,
        archivedCount: list.archivedCount,
        status: AccountsStatus.loaded,
        clearError: true,
      ),
    );
  }

  @override
  void clear() => emit(const AccountsState());

  Future<void> loadIfNeeded() async {
    if (state.status == AccountsStatus.loaded ||
        state.status == AccountsStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() => loadSynced();

  Future<Account> add(Account draft) async {
    final created = await _repo.create(draft);
    emit(state.copyWith(accounts: [...state.accounts, created]));
    return created;
  }

  Future<Account> update(Account account, {double? currentBalance}) async {
    final updated = await _repo.update(account, currentBalance: currentBalance);
    _replace(updated);
    return updated;
  }

  Future<Account> setTrackBalance(
    String id, {
    required bool on,
    double? currentBalance,
  }) async {
    final updated = await _repo.setTrackBalance(
      id,
      on: on,
      currentBalance: currentBalance,
    );
    _replace(updated);
    return updated;
  }

  Future<AccountDetail> getDetail(String id) => _repo.getDetail(id);

  List<Account> get archived => state.archivedAccounts;

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
        archivedAccounts: [
          for (final a in state.archivedAccounts)
            if (a.id != restored.id) a,
        ],
        archivedCount: state.archivedCount > 0 ? state.archivedCount - 1 : 0,
      ),
    );
    return restored;
  }

  Future<Account> remove(String id) async {
    final archived = await _repo.archive(id);
    emit(
      state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
        archivedAccounts: [...state.archivedAccounts, archived],
        archivedCount: state.archivedCount + 1,
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
        archivedAccounts: state.archivedAccounts
            .where((a) => a.id != id)
            .toList(),
        archivedCount: wasArchived && state.archivedCount > 0
            ? state.archivedCount - 1
            : state.archivedCount,
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
    emit(state.copyWith(accounts: [...state.accounts, account]));
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
      ),
    );
  }

  Future<void> saveOrder(List<Account> ordered) async {
    final fresh = await _repo.reorder([for (final a in ordered) a.id]);
    emit(
      state.copyWith(
        accounts: fresh.data,
        totals: fresh.totals,
        archivedCount: fresh.archivedCount,
        status: AccountsStatus.loaded,
        clearError: true,
      ),
    );
  }
}
