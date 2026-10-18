import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/transaction_type.dart';

AppCompactHeroCard txCompactHeroBar(
  BuildContext context, {
  required TransactionType type,
  required String description,
  required double amount,
  String? categoryName,
  IconCode? categoryIcon,
  String symbol = '฿',
  VoidCallback? onTap,
}) {
  final l = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final palette = theme.extension<AppColors>()!;
  final typeColor = txTypeColor(context, type);
  final typeLabel = switch (type) {
    TransactionType.expense => l.transactionTypeExpense,
    TransactionType.income => l.transactionTypeIncome,
    TransactionType.transfer => l.transactionTypeTransfer,
  };
  final text = description.trim();
  final category = type == TransactionType.transfer ? null : categoryName;
  // The category is the title only when there's no description; then the chip
  // would just repeat it.
  final title = text.isNotEmpty ? text : (category ?? typeLabel);
  final showChip = text.isNotEmpty && category != null;
  return AppCompactHeroCard(
    style: txHeroStyle(context, type),
    onTap: onTap,
    title: Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.isNotEmpty
                ? null
                : theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        if (showChip) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '·',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: AppChip(
              label: category,
              icon: IconRegistry.get(
                categoryIcon?.icon,
                fallback: AppIcons.category,
              ),
              color: categoryIcon.tintFor(palette),
              selected: true,
              size: ChipSize.chip,
              maxWidth: 120,
            ),
          ),
        ],
      ],
    ),
    trailing: MoneyText(
      amount,
      symbol: symbol,
      hideable: false,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: typeColor,
      ),
    ),
  );
}
