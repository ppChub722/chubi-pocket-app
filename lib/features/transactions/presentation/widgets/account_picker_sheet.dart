import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/widgets/account_card.dart';

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

/// Bottom sheet for picking one of the user's active accounts — the same
/// 2-column card grid as the accounts page (real [AccountCard]s), with the
/// current pick ring-highlighted ([SelectableFrame]).
///
/// [allowNone] adds a "ไม่ระบุกระเป๋า" tile first (floating transaction).
/// [excludeId] hides one account (the "to" side of a transfer).
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
    final visible = excludeId == null
        ? accounts
        : accounts.where((a) => a.id != excludeId).toList();
    final tiles = <Widget>[
      if (allowNone)
        SelectableFrame(
          selected: selected == null,
          child: _NoneTile(
            label: l.transactionFormAccountNone,
            onTap: () =>
                Navigator.of(context).pop(const AccountPickerCleared()),
          ),
        ),
      for (final a in visible)
        SelectableFrame(
          selected: a.id == selected?.id,
          child: AccountCard(
            account: a,
            horizontal: false,
            onTap: () => Navigator.of(context).pop(AccountPickerSelected(a)),
          ),
        ),
    ];

    return AppSheetScaffold(
      title: title ?? l.transactionFormAccountPickerTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: tiles.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  l.transactionFormAccountPickerEmpty,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              )
            : GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                  // Fixed height: vertical AccountCard (icon · name · type ·
                  // balance + optional credit bar) + the selection ring.
                  mainAxisExtent: 156,
                ),
                children: tiles,
              ),
      ),
    );
  }
}

/// "ไม่ระบุกระเป๋า" — same footprint as an account card, quiet styling.
class _NoneTile extends StatelessWidget {
  const _NoneTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.money_off_outlined,
                  size: 32, color: scheme.onSurfaceVariant),
              const Spacer(),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
