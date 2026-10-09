import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account.dart';

/// "ปรับยอด" bottom sheet (spec §2.5): current balance → the new balance →
/// live difference → optional note → a banner that the difference is
/// booked as an "ปรับยอด" transaction dated today. Resolves the new balance
/// + note, or null on cancel; the caller makes the API call
/// (`POST /v1/accounts/:id/adjust-balance`).
///
/// Credit wallets (card / pay-later) keep debt as a negative balance, so
/// their field asks for the outstanding amount and the result is negated.
/// The field takes a sign (± chip) for every type — an overdrawn account or
/// an overpaid card is a real balance.
Future<({double balance, String? note})?> showAdjustBalanceSheet(
  BuildContext context,
  Account account,
) {
  return showModalBottomSheet<({double balance, String? note})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    useRootNavigator: true,
    builder: (_) => _AdjustBalanceSheet(account: account),
  );
}

class _AdjustBalanceSheet extends StatefulWidget {
  const _AdjustBalanceSheet({required this.account});
  final Account account;

  @override
  State<_AdjustBalanceSheet> createState() => _AdjustBalanceSheetState();
}

class _AdjustBalanceSheetState extends State<_AdjustBalanceSheet> {
  late final TextEditingController _controller;
  final _note = TextEditingController();

  bool get _isCredit => widget.account.type.isCredit;

  @override
  void initState() {
    super.initState();
    final b = widget.account.balance;
    // Credit → the field shows the debt (positive while owing).
    final shown = _isCredit ? -b : b;
    _controller = TextEditingController(text: AmountField.format(shown));
  }

  @override
  void dispose() {
    _controller.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The balance the field describes; null while it doesn't parse.
  double? get _newBalance {
    final v = AmountField.parse(_controller.text);
    if (v == null) return null;
    return _isCredit ? -v : v;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final a = widget.account;
    final symbol = Currencies.symbolOf(a.currency);
    final accent = a.iconCode?.accentColorFor(palette) ?? palette.primary;
    final next = _newBalance;
    // Rounded to satang so float noise never reads as a change.
    final diff = next == null
        ? 0.0
        : ((next - a.balance) * 100).roundToDouble() / 100;
    final canAdjust = next != null && diff != 0;
    final diffText =
        '${diff > 0 ? '+' : '−'}${moneyString(context, diff.abs(), symbol: symbol)}';

    return AppSheetScaffold(
      title: l.accountAdjustBalanceTitle,
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: l.commonCancel,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: l.accountDetailAdjustBalance,
              size: AppButtonSize.large,
              expand: true,
              onPressed: canAdjust
                  ? () => Navigator.of(context).pop((
                      balance: next,
                      note: _note.text.trim().isEmpty
                          ? null
                          : _note.text.trim(),
                    ))
                  : null,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.accountAdjustBalanceCurrentLabel,
                    style: detailLabelStyle(context),
                  ),
                ),
                MoneyText(
                  a.balance,
                  symbol: symbol,
                  style: textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AmountField(
              controller: _controller,
              label: _isCredit
                  ? l.accountAdjustBalanceNewDebtLabel
                  : l.accountAdjustBalanceNewLabel,
              currencySymbol: symbol,
              autofocus: true,
              allowNegative: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.accountAdjustBalanceDiffLabel,
                    style: textTheme.bodyLarge,
                  ),
                ),
                MoneyText(
                  diff,
                  symbol: symbol,
                  tone: MoneyTone.signed,
                  hideable: false,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _note,
              label: l.accountAdjustBalanceNoteLabel,
              prefixIcon: AppIcons.note,
              maxLength: 200,
            ),
            const SizedBox(height: AppSpacing.sm),
            MessageBanner(
              tone: canAdjust ? Tone.info : Tone.neutral,
              message: canAdjust
                  ? l.accountAdjustBalanceWillCreate(diffText)
                  : l.accountAdjustBalanceNoChange,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
