import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../categories/domain/category_tree.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

/// The one transaction row used everywhere (dashboard recent list, the
/// transactions tab, account detail, …) — built on [MoneyListTile] so
/// metrics, colours and the 👁 privacy toggle match every money row.
///
/// Leading: the category's icon exactly as on the categories page (L2/L3
/// inherit their top-level parent's icon code); no category → a type glyph
/// tinted expense / income. Title: category name, else the note. Subtitle: the context
/// the current screen doesn't already show — toggle with [showAccount] /
/// [showDate] (e.g. hide the account on that account's own page, hide the
/// date under a date header) — plus a split marker. Tags, if any, take a
/// third line in their short form ([TagShortList]).
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

    final categories = context.watch<CategoriesCubit>();
    final cat = tx.category != null ? categories.byId(tx.category!.id) : null;
    final Widget leading = cat != null
        ? IconDisplay(
            type: IconType.category,
            size: 36,
            iconCode: CategoryTree.resolveIconCode(
              cat,
              categories.state.categories,
            ),
          )
        : IconBubble(
            icon: _typeIcon(tx.type),
            color: switch (tx.type) {
              TransactionType.expense => palette.expense,
              TransactionType.income => palette.income,
              TransactionType.transfer => scheme.onSurfaceVariant,
            },
            size: 36,
          );

    final categoryName = tx.category?.name ?? '';
    final title = categoryName.isNotEmpty
        ? categoryName
        : ((tx.note?.isNotEmpty ?? false) ? tx.note! : '—');

    final parts = <String>[
      if (categoryName.isNotEmpty && (tx.note?.isNotEmpty ?? false)) tx.note!,
      if (showAccount && tx.account != null) tx.account!.name,
      if (showDate) _date(context, l, tx.date),
    ];

    return MoneyListTile(
      leading: leading,
      title: title,
      amount: tx.signedAmount,
      subtitle: Row(
        children: [
          if (showAccount && tx.account == null) ...[
            AppBadge(label: l.transactionFormAccountNone),
            if (parts.isNotEmpty) const SizedBox(width: AppSpacing.xs),
          ],
          if (parts.isNotEmpty) Flexible(child: Text(parts.join(' · '))),
          if (tx.hasSplits) ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(AppIcons.split),
          ],
        ],
      ),
      // Third line: the short tags (`#name` in each tag's colour).
      footer: tx.tags.isEmpty
          ? null
          : TagShortList(tags: [for (final t in tx.tags) t.asTag]),
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
