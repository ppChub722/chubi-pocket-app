import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../accounts/domain/account.dart';
import '../../../../shared/icon_maker/icon_registry.dart';

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

/// Modal bottom sheet for picking one of the user's active accounts.
///
/// When [allowNone] is true, a "ไม่ระบุกระเป๋า" row appears at the top
/// so the user can explicitly clear the account (floating transaction).
/// The `excludeId` parameter hides one account — used for the "to"
/// picker so the user can't pick the same account twice.
Future<AccountPickerResult?> showAccountPickerSheet({
  required BuildContext context,
  required List<Account> accounts,
  Account? selected,
  String? excludeId,
  String? title,
  bool allowNone = false,
}) {
  return showModalBottomSheet<AccountPickerResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AccountPickerBody(
      accounts: accounts,
      selected: selected,
      excludeId: excludeId,
      title: title,
      allowNone: allowNone,
    ),
  );
}

class _AccountPickerBody extends StatelessWidget {
  const _AccountPickerBody({
    required this.accounts,
    required this.selected,
    required this.excludeId,
    required this.title,
    required this.allowNone,
  });

  final List<Account> accounts;
  final Account? selected;
  final String? excludeId;
  final String? title;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final visible = excludeId == null
        ? accounts
        : accounts.where((a) => a.id != excludeId).toList();
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              title ?? l.transactionFormAccountPickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (allowNone)
            ListTile(
              leading:
                  Icon(Icons.account_balance_wallet_outlined, color: scheme.onSurfaceVariant),
              title: Text(l.transactionFormAccountNone),
              trailing: selected == null
                  ? Icon(Icons.check, color: scheme.primary)
                  : null,
              onTap: () =>
                  Navigator.of(context).pop(const AccountPickerCleared()),
            ),
          if (visible.isEmpty && !allowNone)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l.transactionFormAccountPickerEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            )
          else if (visible.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (ctx, i) {
                  final a = visible[i];
                  final isSelected = a.id == selected?.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          a.iconCode?.bgColorFor(palette) ?? scheme.outline,
                      child: Icon(
                          IconRegistry.get(a.iconCode?.icon,
                              fallback: Icons.account_balance_wallet_outlined),
                          color: Colors.white,
                          size: 20),
                    ),
                    title: Text(a.name),
                    subtitle: Text(
                      '${CurrencyFormatter.format(a.balance)} · ${a.currency}',
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: scheme.primary)
                        : null,
                    onTap: () =>
                        Navigator.of(ctx).pop(AccountPickerSelected(a)),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
