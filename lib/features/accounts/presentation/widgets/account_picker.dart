import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account.dart';
import '../cubit/accounts_cubit.dart';
import '../pages/account_detail_page.dart';

sealed class AccountPickOutcome {
  const AccountPickOutcome();
}

class AccountPicked extends AccountPickOutcome {
  const AccountPicked(this.account);
  final Account account;
}

/// "ไม่ระบุกระเป๋า" was picked.
class AccountPickedNone extends AccountPickOutcome {
  const AccountPickedNone();
}

class AccountPicks {
  const AccountPicks({
    this.accounts = const [],
    this.ids = const [],
    this.none = false,
  });

  final List<Account> accounts;

  /// Every ticked id in tick order, also one no longer known (a ticked wallet
  /// that left the cache), so a caller can keep what it had for it.
  final List<String> ids;

  /// "ไม่ระบุกระเป๋า" is ticked.
  final bool none;
}

/// The wallet picker every page opens, always as wallet cards: [one] or
/// [many]. [accounts] = the list to start from; without it every active wallet
/// of the cache, and in [many] also an archived one that is already ticked.
abstract final class AccountPicker {
  static Future<AccountPickOutcome?> one(
    BuildContext context, {
    String? selectedId,
    Set<String> excludeIds = const {},
    bool allowNone = false,
    String? noneLabel,
    bool allowCreate = false,
    String? title,
    List<Account>? accounts,
    bool useRootNavigator = true,
  }) async {
    final r = await _open(
      context,
      multi: false,
      selected: {?selectedId},
      excludeIds: excludeIds,
      allowNone: allowNone,
      noneSelected: allowNone && selectedId == null,
      noneLabel: noneLabel,
      allowCreate: allowCreate,
      title: title,
      accounts: accounts,
      useRootNavigator: useRootNavigator,
    );
    if (r == null) return null;
    if (r.result.none) return const AccountPickedNone();
    final hit = r.lookup(r.result.id);
    return hit == null ? null : AccountPicked(hit);
  }

  static Future<AccountPicks?> many(
    BuildContext context, {
    Set<String> selected = const {},
    bool allowNone = false,
    bool noneSelected = false,
    String? noneLabel,
    String? title,
    List<Account>? accounts,
    bool useRootNavigator = true,
  }) async {
    final r = await _open(
      context,
      multi: true,
      selected: selected,
      allowNone: allowNone,
      noneSelected: noneSelected,
      noneLabel: noneLabel,
      title: title,
      accounts: accounts,
      useRootNavigator: useRootNavigator,
    );
    if (r == null) return null;
    return AccountPicks(
      accounts: [for (final id in r.result.ids) ?r.lookup(id)],
      ids: r.result.ids,
      none: r.result.none,
    );
  }

  static Future<_Opened?> _open(
    BuildContext context, {
    required bool multi,
    Set<String> selected = const {},
    Set<String> excludeIds = const {},
    bool allowNone = false,
    bool noneSelected = false,
    String? noneLabel,
    bool allowCreate = false,
    String? title,
    List<Account>? accounts,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    AccountsCubit? cache;
    try {
      cache = context.read<AccountsCubit>();
    } catch (_) {
      cache = null;
    }
    final keepArchived = multi ? selected : const <String>{};
    List<Account> everyOf(AccountsState s) => [
      for (final a in s.accounts)
        if (!excludeIds.contains(a.id)) a,
      for (final a in s.archivedAccounts)
        if (keepArchived.contains(a.id) && !excludeIds.contains(a.id)) a,
    ];
    final start = accounts == null
        ? (cache == null ? const <Account>[] : everyOf(cache.state))
        : [
            for (final a in accounts)
              if (!excludeIds.contains(a.id)) a,
          ];
    final startIds = {for (final a in start) a.id};
    final wasEvery =
        accounts == null ||
        (cache != null &&
            cache.state.accounts.every(
              (a) => excludeIds.contains(a.id) || startIds.contains(a.id),
            ));
    var latest = start;
    final feed = cache == null
        ? null
        : CubitFeed<AccountsState, PickerData>(cache, (s) {
            latest = _fresh(start, everyOf(s), addNew: wasEvery);
            return PickerData(
              _items(latest),
              loading: s.status == AccountsStatus.loading,
              error: s.error,
            );
          });
    Account? created;
    Account? lookup(String? id) {
      if (id == null) return null;
      if (created?.id == id) return created;
      return latest.where((a) => a.id == id).firstOrNull ??
          start.where((a) => a.id == id).firstOrNull;
    }

    try {
      final result = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        ItemPickerSheet(
          title:
              title ??
              (multi
                  ? l.multiPickWalletsTitle
                  : l.transactionFormAccountPickerTitle),
          items: _items(latest),
          live: feed?.listenable,
          onRefresh: cache == null
              ? null
              : syncRefreshOf(context, const {SyncSet.accounts}),
          multi: multi,
          layout: PickerLayout.cards,
          cardBuilder: (_, item, _, onTap) => AccountCard(
            account: item.data! as Account,
            horizontal: false,
            onTap: onTap,
          ),
          selected: selected,
          noneSelected: noneSelected,
          none: allowNone
              ? PickerNone(
                  label:
                      noneLabel ??
                      (multi
                          ? l.txFilterNoWallet
                          : l.transactionFormAccountNone),
                  icon: AppIcons.noWallet,
                )
              : null,
          create: allowCreate
              ? PickerCreate(
                  label: (_) => l.accountsAddNew,
                  onCreate: (_) async {
                    created = await Navigator.of(context, rootNavigator: true)
                        .push(
                          MaterialPageRoute<Account>(
                            builder: (_) =>
                                const AccountDetailPage(popOnCreate: true),
                          ),
                        );
                    return created?.id;
                  },
                )
              : null,
          emptyText: l.transactionFormAccountPickerEmpty,
          noMatchText: l.multiPickNoMatch,
          confirmLabel: multi
              ? (n) => n == 0 ? l.commonOk : l.multiPickConfirm(n)
              : null,
        ),
      );
      if (result == null) return null;
      return _Opened(result, lookup);
    } finally {
      unawaited(feed?.dispose());
    }
  }

  /// The list the picker was opened with, kept up to date while it is open:
  /// renamed or re-balanced wallets change, archived ones leave, and new ones
  /// join when the list was every wallet.
  static List<Account> _fresh(
    List<Account> opened,
    List<Account> every, {
    required bool addNew,
  }) {
    final byId = {for (final a in every) a.id: a};
    final out = [for (final a in opened) ?byId[a.id]];
    if (addNew) {
      final have = {for (final a in out) a.id};
      out.addAll(every.where((a) => !have.contains(a.id)));
    }
    return out;
  }

  static List<PickerItem> _items(List<Account> wallets) => [
    for (final a in wallets) PickerItem(id: a.id, title: a.name, data: a),
  ];
}

class _Opened {
  const _Opened(this.result, this.lookup);

  final PickerResult result;
  final Account? Function(String? id) lookup;
}
