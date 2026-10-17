import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/pages/account_detail_page.dart';

/// Result returned by [showAccountPickerSheet]. Distinct from `null`
/// (user dismissed) — [AccountPickerCleared] means "ไม่ระบุกระเป๋า".
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

/// Pick one of the user's active wallets, in the kit's
/// [AccountPickerSheet] (owner 2026-10-10): header + ✕, the same card grid as
/// the wallets page (real [AccountCard]s), the current pick highlighted. The
/// thin wrapper: it maps [Account] ⇄ the organism's plain items, supplies the
/// l10n words and owns the create-wallet navigation.
///
/// [allowNone] adds a "ไม่ระบุกระเป๋า" tile first (floating transaction).
/// [excludeId] hides one account (the "to" side of a transfer).
/// [allowCreate] adds "＋ เพิ่มกระเป๋า" under the grid: the create page
/// opens over the sheet; saving there picks the new wallet and closes the
/// picker, back returns to the picker (owner 2026-10-10).
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
            // The create page over the sheet — on the root navigator: a
            // routed push (/accounts/new) from inside this modal would land
            // under it. Saving there pops with the new wallet (no router
            // replace — QA W2) → pick it; back (nothing saved) returns to
            // the picker.
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
