import 'package:flutter/material.dart';

import '../../../features/transactions/domain/transaction_type.dart';
import '../../ui.dart';

enum EntryField { wallet, category }

class EntryCard extends StatelessWidget {
  const EntryCard({
    required this.type,
    required this.amount,
    required this.title,
    required this.dateLabel,
    this.walletRow,
    this.categoryRow,
    this.toWalletRow,
    this.flowRow,
    this.titleHint,
    this.showTitle = true,
    this.onTypeChanged,
    this.onPickDate,
    this.missing = const {},
    this.symbol = '฿',
    this.autofocus = false,
    this.compact = false,
    this.amountError,
    this.amountFocus,
    this.titleFocus,
    this.amountNote,
    this.amountLabel,
    this.debt = false,
    this.repay = false,
    this.typeBadge,
    this.accentColor,
    this.dateNote,
    super.key,
  });

  final TransactionType type;
  final ValueChanged<TransactionType>? onTypeChanged;

  final TextEditingController amount;
  final TextEditingController title;
  final String dateLabel;
  final VoidCallback? onPickDate;

  final Widget? walletRow;

  final Widget? categoryRow;

  final Widget? toWalletRow;

  /// Instead of the wallet / category rows: a [FlowCards] row (transfer, debt,
  /// saving).
  final Widget? flowRow;

  final String? titleHint;
  final bool showTitle;

  final Set<EntryField> missing;

  final String symbol;
  final bool autofocus;
  final bool compact;
  final String? amountError;
  final FocusNode? amountFocus;
  final FocusNode? titleFocus;

  final Widget? amountNote;

  /// The word over the amount; default "จำนวนเงิน" (ผูกกับ: "ยอดบิล").
  final String? amountLabel;

  /// Debt words on the type chips (รอรับ / รอจ่าย).
  final bool debt;

  /// Repayment words on the type chips (จ่ายคืน / รับคืน).
  final bool repay;

  final Widget? typeBadge;
  final Color? accentColor;

  final Widget? dateNote;

  Widget _slot(BuildContext context, Widget row, {required bool flagged}) {
    if (!flagged) return row;
    final error = Theme.of(context).colorScheme.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: error),
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpacing.xxs), child: row),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = type == TransactionType.transfer;
    final walletMissing = missing.contains(EntryField.wallet);
    // The from → to cards stand where the wallet + category chip rows stand:
    // exactly as tall as those two rows, so switching the type (or the tab)
    // never moves the card.
    final gap = HeroMetrics.of(context).itemGap;
    final twoRows = ChipSize.control.heightOf(context) * 2 + gap;
    return TransactionHeroCard(
      type: type,
      onTypeChanged: onTypeChanged,
      amount: amount,
      title: title,
      dateLabel: dateLabel,
      onPickDate: onPickDate,
      symbol: symbol,
      autofocus: autofocus,
      compact: compact,
      amountError: amountError,
      amountFocus: amountFocus,
      titleFocus: titleFocus,
      amountNote: amountNote,
      amountLabel: amountLabel,
      titleHint: titleHint,
      showTitle: showTitle,
      debt: debt,
      repay: repay,
      typeBadge: typeBadge,
      accentColor: accentColor,
      dateNote: dateNote,
      inline: true,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flowRow != null)
            _slot(
              context,
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: twoRows),
                child: flowRow,
              ),
              flagged: walletMissing,
            ),
          if (walletRow != null)
            _slot(context, walletRow!, flagged: walletMissing),
          if (isTransfer && toWalletRow != null) ...[
            if (walletRow != null) SizedBox(height: gap),
            _slot(context, toWalletRow!, flagged: walletMissing),
          ],
          if (!isTransfer && categoryRow != null) ...[
            if (walletRow != null) SizedBox(height: gap),
            _slot(
              context,
              categoryRow!,
              flagged: missing.contains(EntryField.category),
            ),
          ],
        ],
      ),
    );
  }
}
