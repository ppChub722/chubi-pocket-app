import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/pages/account_detail_page.dart';

sealed class AccountPickerResult {
  const AccountPickerResult();
}

class AccountPickerSelected extends AccountPickerResult {
  const AccountPickerSelected(this.account);
  final Account account;
}

class AccountPickerCleared extends AccountPickerResult {
  const AccountPickerCleared();
}

WalletPickItem _walletItem(Account a) => WalletPickItem(
  id: a.id,
  name: a.name,
  icon: a.type.icon,
  cardBuilder: (_, onTap) =>
      AccountCard(account: a, horizontal: false, onTap: onTap),
);

/// The wallets of the list the sheet was opened with, brought up to date from
/// the cache while it is open: renamed or re-balanced ones change, archived
/// ones leave, and a new wallet joins when the list was every active wallet.
List<Account> _freshWallets(
  List<Account> opened,
  List<Account> cached,
  bool wasEveryActive,
  String? excludeId,
) {
  final byId = {for (final a in cached) a.id: a};
  final out = [for (final a in opened) ?byId[a.id]];
  if (wasEveryActive) {
    final have = {for (final a in out) a.id};
    for (final a in cached) {
      if (!have.contains(a.id) && a.id != excludeId) out.add(a);
    }
  }
  return out;
}

Future<AccountPickerResult?> showAccountPickerSheet({
  required BuildContext context,
  required List<Account> accounts,
  Account? selected,
  String? excludeId,
  String? title,
  bool allowNone = false,
  bool allowCreate = false,
}) async {
  final l = AppLocalizations.of(context)!;
  final all = excludeId == null
      ? accounts
      : accounts.where((a) => a.id != excludeId).toList();
  AccountsCubit? cache;
  try {
    cache = context.read<AccountsCubit>();
  } catch (_) {
    cache = null; // no cache here (a test, the hub): the list as given
  }
  final refresh = cache == null
      ? null
      : syncRefreshOf(context, const {SyncSet.accounts});
  final wasEveryActive =
      cache != null &&
      all.length == cache.state.accounts.where((a) => a.id != excludeId).length;
  var latest = all;
  final feed = cache == null
      ? null
      : CubitFeed<AccountsState, List<WalletPickItem>>(cache, (s) {
          latest = _freshWallets(all, s.accounts, wasEveryActive, excludeId);
          return [for (final a in latest) _walletItem(a)];
        });
  Account? created;
  try {
    final pick = await showAccountPickSheet(
      context,
      wallets: [for (final a in all) _walletItem(a)],
      live: feed?.listenable,
      onRefresh: refresh,
      labels: AccountPickerLabels(
        title: title ?? l.transactionFormAccountPickerTitle,
        none: l.transactionFormAccountNone,
        create: l.accountsAddNew,
        empty: l.transactionFormAccountPickerEmpty,
      ),
      selectedId: selected?.id,
      allowNone: allowNone,
      onCreate: allowCreate
          ? () async {
              // The create page over the sheet — on the root navigator: a routed
              // push (/accounts/new) from inside this modal would land under it.
              created = await Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<Account>(
                  builder: (_) => const AccountDetailPage(popOnCreate: true),
                ),
              );
              return created?.id;
            }
          : null,
    );
    return switch (pick) {
      null => null,
      AccountPickNone() => const AccountPickerCleared(),
      AccountPickWallet(:final id) => AccountPickerSelected(
        latest.firstWhere(
          (a) => a.id == id,
          orElse: () =>
              all.firstWhere((a) => a.id == id, orElse: () => created!),
        ),
      ),
    };
  } finally {
    await feed?.dispose();
  }
}
