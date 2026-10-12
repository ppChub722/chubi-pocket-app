import 'package:flutter/material.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

/// The one transaction row used everywhere (dashboard recent list, the
/// transactions tab, account detail, …) — built on [MoneyListTile] so
/// metrics, colours and the 👁 privacy toggle match every money row.
///
/// Leading: the category's icon exactly as on the categories page (L2/L3
/// carry their own icon); no category → a type glyph
/// tinted expense / income. Title: the description, else the category name
/// (system ones in the user's language). Subtitle: the context the current
/// screen doesn't already show — toggle with [showAccount] /
/// [showDate] (e.g. hide the account on that account's own page, hide the
/// date under a date header) — plus the tags (`#name` in each tag's
/// colour) on the same line, and a split marker.
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

  /// Defaults to opening the transaction detail.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;

    // Everything comes embedded in the row (API v2): the category's own
    // icon (L2/L3 are not resolved through their parent) and name.
    final cat = tx.category;
    final Widget leading = cat != null
        ? IconDisplay(type: IconType.category, size: 36, iconCode: cat.iconCode)
        : IconTile(
            icon: _typeIcon(tx.type),
            color: switch (tx.type) {
              TransactionType.expense => palette.expense,
              TransactionType.income => palette.income,
              TransactionType.transfer => scheme.onSurfaceVariant,
            },
            size: 36,
          );

    // The record's own title ("what for") first, else its category (system
    // ones in the user's language).
    final categoryName = cat != null
        ? categoryDisplayName(
            l,
            cat.toCategory().copyWith(systemKind: cat.systemKind),
          )
        : '';
    final description = tx.description?.trim() ?? '';
    final title = description.isNotEmpty
        ? description
        : (categoryName.isNotEmpty ? categoryName : '—');

    // The wallet's own icon inside its mini chip; unknown wallet → no icon.
    final wallet = tx.account;

    // The shared row (owner 2026-10-11): title + wallet chip, then
    // `category · #tags`; the date lives in the list's day headers.
    return TxRow(
      leading: leading,
      title: title,
      amount: tx.signedAmount,
      walletLabel: showAccount
          ? (tx.account?.name ?? l.transactionFormAccountNone)
          : null,
      walletIcon: wallet == null
          ? null
          : IconDisplay(
              type: IconType.account,
              size: 14,
              iconCode: wallet.iconCode,
            ),
      category: description.isNotEmpty && categoryName.isNotEmpty
          ? categoryName
          : null,
      extra: showDate ? _date(context, l, tx.date) : null,
      tags: [
        for (final t in tx.tags)
          TextSpan(
            text: '#${t.name}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tagColor(t.asTag.iconCode, palette),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
      hasSplits: tx.hasSplits,
      onTap: onTap ?? () => openPage(context, '/transactions/${tx.id}'),
    );
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

  static IconData _typeIcon(TransactionType t) => switch (t) {
    TransactionType.expense => AppIcons.expense,
    TransactionType.income => AppIcons.income,
    TransactionType.transfer => AppIcons.transfer,
  };
}
