import 'package:flutter/material.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;

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

    final wallet = tx.account;
    final walletCode = wallet?.iconCode;
    final walletFill = walletCode?.background != null
        ? walletCode!.bgColorFor(palette)
        : null;
    final walletOnFill =
        walletFill != null && (walletCode?.iconColors.isNotEmpty ?? false)
        ? resolveColor(walletCode!.iconColors.first, palette)
        : null;

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
      walletFill: walletFill,
      walletOnFill: walletOnFill,
      walletGlyph: walletFill == null
          ? null
          : IconRegistry.get(
              walletCode!.icon,
              fallback: IconType.account.fallbackIcon,
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
