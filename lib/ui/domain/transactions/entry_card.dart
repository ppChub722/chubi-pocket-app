import 'package:flutter/material.dart';

import '../../../features/transactions/domain/transaction_type.dart';
import '../../ui.dart';

/// A field of the [EntryCard] that can be flagged as missing.
enum EntryField { wallet, category }

/// The entry card of quick create and the pending drafts (owner 2026-10-12):
/// ONE card holding everything you fill in first —
///
///   [−รายจ่าย] [+รายรับ] [⇄โอน]              [📅 วันนี้]
///   ค่าอะไร?                                      ฿1,250
///   [💳] [＋ เลือกกระเป๋า] [กสิกร] [เงินสด]        ← [walletRow]
///   [🏷] [＋ เลือกหมวด] [อาหาร] [เดินทาง]           ← [categoryRow]
///
/// A transfer has no category: [walletRow] is the source and [toWalletRow]
/// the destination (two rows). The tags row sits OUTSIDE, right below the
/// card (the caller places it).
///
/// Values and callbacks only: no cubit reads in here, so a draft with
/// nothing filled in yet can feed it (a null amount / wallet / category is
/// just an empty field). The rows are slots — the caller passes the wallet
/// and category chip rows it built from resolved display data.
/// [missing] flags a row the draft still lacks with a danger outline.
///
/// The card is a [TxHeroCard] (its type chips, swipe, amount and
/// description) with the rows as its footer, so it looks like the detail
/// hero and the type colour wash follows the type.
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
    this.debt = false,
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

  /// The wallet chip row (a transfer: the source wallet). Null = no wallet
  /// row (a debt written to the ledger only).
  final Widget? walletRow;

  /// The category chip row — null for a transfer.
  final Widget? categoryRow;

  /// A transfer's destination wallet row.
  final Widget? toWalletRow;

  /// Instead of the wallet / category rows: a [FlowCards] row (transfer, debt,
  /// saving).
  final Widget? flowRow;

  /// The description's placeholder ("จ่ายค่าอะไร?" …); [showTitle] false = no
  /// description (a transfer).
  final String? titleHint;
  final bool showTitle;

  /// Rows to flag as still missing (danger outline).
  final Set<EntryField> missing;

  final String symbol;
  final bool autofocus;
  final bool compact;
  final String? amountError;
  final FocusNode? amountFocus;
  final FocusNode? titleFocus;

  /// A line under the amount (the split share).
  final Widget? amountNote;

  /// Debt mode: Paid / Received in place of the type (see
  /// [TxHeroCard.debt]); [categoryRow] holds the PERSON row.
  final bool debt;

  /// See [TxHeroCard.typeBadge] / [TxHeroCard.accentColor].
  final Widget? typeBadge;
  final Color? accentColor;

  /// See [TxHeroCard.dateNote].
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
    return TxHeroCard(
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
      titleHint: titleHint,
      showTitle: showTitle,
      debt: debt,
      typeBadge: typeBadge,
      accentColor: accentColor,
      dateNote: dateNote,
      inline: true,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flowRow != null) _slot(context, flowRow!, flagged: walletMissing),
          if (walletRow != null)
            _slot(context, walletRow!, flagged: walletMissing),
          if (isTransfer && toWalletRow != null) ...[
            if (walletRow != null) const SizedBox(height: HeroSpacing.itemGap),
            _slot(context, toWalletRow!, flagged: walletMissing),
          ],
          if (!isTransfer && categoryRow != null) ...[
            if (walletRow != null) const SizedBox(height: HeroSpacing.itemGap),
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
