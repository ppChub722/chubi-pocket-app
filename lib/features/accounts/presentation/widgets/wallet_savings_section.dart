import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account.dart';

/// The wallet page's "เงินออม" section (Saving goals v2): the real balance,
/// what is saved (per goal + the spare), what is still available, and a red
/// warning line when the savings exceed the balance (nothing is blocked).
///
/// Hidden ([shows] false) when nothing is saved here. A wallet that does not
/// track its balance shows the saved buckets only — no balance, no available.
class WalletSavingsSection extends StatelessWidget {
  const WalletSavingsSection({
    required this.account,
    this.first = false,
    super.key,
  });

  final Account account;
  final bool first;

  /// Whether the section has anything to show for [account].
  static bool shows(Account account) {
    final s = account.savings;
    return s != null && !s.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final s = account.savings;
    if (s == null || s.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final symbol = context.readUserCurrencySymbol;
    final tracked = account.trackBalance && s.available != null;
    Widget money(num v, {TextStyle? style}) =>
        MoneyText(v, symbol: symbol, style: style);
    final bold = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);

    return SectionCard(
      first: first,
      title: l.walletSavingsTitle,
      description: l.walletSavingsDescription,
      children: [
        if (tracked)
          DetailRow(label: l.walletSavingsBalance, trailing: money(s.balance)),
        for (final b in s.buckets) _bucketRow(context, b, symbol),
        if (tracked) ...[
          DetailRow(label: l.walletSavingsSaved, trailing: money(s.saved)),
          DetailRow(
            label: l.walletSavingsAvailable,
            trailing: money(s.available!, style: bold),
          ),
        ],
        if (s.savedExceedsBalance)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppMessage(
              tone: Tone.danger,
              message: l.walletSavingsOver(
                moneyString(context, s.overBy, symbol: symbol),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bucketRow(
    BuildContext context,
    WalletSavingsBucket b,
    String symbol,
  ) {
    // A goal opens itself; the spare opens the list (it is shown there).
    final target = b.isGoal
        ? (b.id == null ? null : '/saving-goals/${b.id}')
        : '/saving-goals';
    return DetailRow(
      label: b.name,
      leading: IconCodeWidget(
        iconCode: b.iconCode,
        size: 32,
        fallbackIcon: b.isGoal ? AppIcons.savingGoal : AppIcons.savingDeposit,
      ),
      trailing: MoneyText(b.amount, symbol: symbol),
      showChevron: target != null,
      onTap: target == null ? null : () => openPage(context, target),
    );
  }
}
