import 'package:flutter/material.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    this.showAccount = true,
    this.showDate = false,
    this.onTap,
    super.key,
  });

  final Transaction transaction;
  final bool showAccount;
  final bool showDate;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final l = AppLocalizations.of(context)!;
    final cat = tx.category;

    final categoryName = cat != null
        ? categoryDisplayName(
            l,
            cat.toCategory().copyWith(systemKind: cat.systemKind),
          )
        : '';
    final description = tx.description?.trim() ?? '';
    final debt = tx.counterparty;
    final title = description.isNotEmpty
        ? description
        : debt != null
        ? debtAutoTitle(
            l,
            direction: debt.direction,
            isRepayment: false,
            name: debt.person.name,
          )
        : (categoryName.isNotEmpty ? categoryName : '—');

    final wallet = tx.account;
    final day = DateFormatter.parseDay(tx.date);
    final now = DateTime.now();
    final upcoming =
        day != null && day.isAfter(DateTime(now.year, now.month, now.day));

    return TxListRow(
      kind: switch (tx.type) {
        TransactionType.expense => TxListKind.expense,
        TransactionType.income => TxListKind.income,
        TransactionType.transfer => TxListKind.transfer,
      },
      icon: cat?.iconCode,
      title: title,
      source: sourceOf(tx),
      dimmed: upcoming,
      status: upcoming
          ? ListRowChip(dueLabel(l, date: day, withDate: false))
          : null,
      wallet: showAccount && wallet != null
          ? walletRowChip(
              context,
              name: wallet.name,
              iconCode: wallet.iconCode,
              type: wallet.type,
            )
          : null,
      parts: [
        if (description.isNotEmpty) categoryName,
        if (showDate) _date(context, l, tx.date),
      ],
      glyphs: [
        if (tx.hasSplits)
          ListRowGlyph(AppIcons.shared, text: '${tx.splitCount + 1}'),
      ],
      tags: [
        for (final t in tx.tags)
          tagSpan(context, t.name, iconCode: t.asTag.iconCode),
      ],
      amount: MoneyText(tx.signedAmount, tone: MoneyTone.signed),
      onTap: onTap ?? () => openPage(context, '/transactions/${tx.id}'),
    );
  }

  /// Where [tx] came from: an installment before its recurring rule.
  static TxSource? sourceOf(Transaction tx) {
    final rec = tx.recurringItem;
    if (rec != null) {
      return rec.total != null ? TxSource.installment : TxSource.recurring;
    }
    if (tx.eventBill != null || tx.projectId != null) return TxSource.event;
    if (tx.counterparty != null || tx.repaymentPerson != null) {
      return TxSource.debt;
    }
    return null;
  }

  static String _date(BuildContext context, AppLocalizations l, String ymd) {
    final d = DateFormatter.parseDay(ymd);
    if (d == null) return ymd;
    return DateFormatter.friendly(
      d,
      today: l.commonToday,
      yesterday: l.commonYesterday,
      locale: Localizations.localeOf(context).languageCode,
    );
  }
}
