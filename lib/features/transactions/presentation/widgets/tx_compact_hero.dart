import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/transaction_type.dart';
import 'tx_hero_card.dart';

/// The transaction's [CompactHeroBar] (owner 2026-10-11) — the detail page
/// pins it under the top bar once the hero has scrolled away, view and
/// edit alike:
///
///   ข้าวมันไก่ · [🍜 อาหาร]                          ฿1,250
///
/// The title is the description, else the category's name, else the type
/// (title = description ?? category). A small category chip in its icon and
/// colour follows the description after a "·" — never beside a title that
/// already is the category, and none for a transfer. The amount stays in
/// the type's colour. [onTap] = back to the hero.
CompactHeroBar txCompactHeroBar(
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
  // The category is the title only when there's no description; then the
  // chip would just repeat it.
  final title = text.isNotEmpty ? text : (category ?? typeLabel);
  final showChip = text.isNotEmpty && category != null;
  return CompactHeroBar(
    style: txHeroStyle(context, type),
    onTap: onTap,
    title: Row(
      children: [
        // The description gives way first, then the chip.
        Flexible(
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (showChip) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '·',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Flexible(
            child: AppChip(
              label: category,
              icon: IconRegistry.get(
                categoryIcon?.icon,
                fallback: AppIcons.category,
              ),
              color: categoryIcon?.accentColorFor(palette) ?? palette.primary,
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
