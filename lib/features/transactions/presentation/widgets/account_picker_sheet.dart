import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/pages/account_detail_page.dart';
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

/// Pick one of the user's active wallets, on the kit [PickerSheet] (owner
/// 2026-10-10): header + ✕, the same card grid as the wallets page (real
/// [AccountCard]s), the current pick highlighted ([SelectableFrame]: a
/// tint + ring, no ✓). Search only with more than 8 wallets.
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
}) {
  return showAppSheetCustom<AccountPickerResult>(
    context,
    builder: (_) => _AccountPicker(
      title:
          title ??
          AppLocalizations.of(context)!.transactionFormAccountPickerTitle,
      accounts: accounts,
      selected: selected,
      excludeId: excludeId,
      allowNone: allowNone,
      allowCreate: allowCreate,
    ),
  );
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.title,
    required this.accounts,
    required this.selected,
    required this.excludeId,
    required this.allowNone,
    required this.allowCreate,
  });

  final String title;
  final List<Account> accounts;
  final Account? selected;
  final String? excludeId;
  final bool allowNone;
  final bool allowCreate;

  /// The create page over the sheet — on the root navigator: a routed push
  /// (/accounts/new) from inside this modal would land under it. A wallet
  /// that wasn't there before is the one just made → pick it.
  Future<void> _create(BuildContext context) async {
    final cubit = context.read<AccountsCubit>();
    final before = {for (final a in cubit.state.accounts) a.id};
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => const AccountDetailPage()));
    if (!context.mounted) return;
    final created = cubit.state.accounts
        .where((a) => !before.contains(a.id))
        .lastOrNull;
    if (created != null) {
      Navigator.of(context).pop(AccountPickerSelected(created));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final all = excludeId == null
        ? accounts
        : accounts.where((a) => a.id != excludeId).toList();
    return PickerSheet(
      title: title,
      searchable: all.length > 8,
      footer: allowCreate
          ? PickerCreateRow(
              label: l.accountsAddNew,
              onTap: () => _create(context),
            )
          : null,
      builder: (context, q) {
        final scheme = Theme.of(context).colorScheme;
        final visible = q.isEmpty
            ? all
            : all.where((a) => a.name.toLowerCase().contains(q)).toList();
        final tiles = <Widget>[
          if (allowNone && q.isEmpty)
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
                onTap: () =>
                    Navigator.of(context).pop(AccountPickerSelected(a)),
              ),
            ),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: tiles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    l.transactionFormAccountPickerEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    // Same columns as the wallets page.
                    crossAxisCount:
                        MediaQuery.sizeOf(context).shortestSide >= 600 ? 3 : 2,
                    mainAxisSpacing: AppSpacing.xs,
                    crossAxisSpacing: AppSpacing.xs,
                    // Fixed height: vertical AccountCard (icon · name · type
                    // · balance + optional credit bar) + the selection ring.
                    mainAxisExtent: 156,
                  ),
                  children: tiles,
                ),
        );
      },
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
              Icon(AppIcons.noWallet, size: 32, color: scheme.onSurfaceVariant),
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
