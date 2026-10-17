import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
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
  Account? created;
  final pick = await showAccountPickSheet(
    context,
    wallets: [
      for (final a in all)
        WalletPickItem(
          id: a.id,
          name: a.name,
          icon: a.type.icon,
          cardBuilder: (_, onTap) =>
              AccountCard(account: a, horizontal: false, onTap: onTap),
        ),
    ],
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
      all.firstWhere((a) => a.id == id, orElse: () => created!),
    ),
  };
}
