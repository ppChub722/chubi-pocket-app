import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/widgets/type_indicator.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/transaction_type.dart';
import 'tx_hero_card.dart';

/// The transaction's [CompactHeroBar] (owner 2026-10-11) — the detail page
/// pins it under the top bar once the hero has scrolled away, view and
/// edit alike:
///
///   [− รายจ่าย]  ข้าวมันไก่              [🍜 อาหาร]  ฿1,250
///
/// A small type chip · the description (else the type) · a small category
/// chip in its icon and colour (none for a transfer or no category) · the
/// amount in the type's colour. [onTap] = back to the hero.
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
  final palette = Theme.of(context).extension<AppColors>()!;
  final typeColor = txTypeColor(context, type);
  final typeLabel = switch (type) {
    TransactionType.expense => l.transactionTypeExpense,
    TransactionType.income => l.transactionTypeIncome,
    TransactionType.transfer => l.transactionTypeTransfer,
  };
  final text = description.trim();
  return CompactHeroBar(
    onTap: onTap,
    leading: type == TransactionType.transfer
        ? LabelPill(label: typeLabel, icon: AppIcons.transfer, color: typeColor)
        : TypeIndicator(isIncome: type == TransactionType.income),
    title: Text(text.isEmpty ? typeLabel : text),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (categoryName != null && type != TransactionType.transfer) ...[
          ConstrainedBox(
            // The description gives way first, then this.
            constraints: const BoxConstraints(maxWidth: 120),
            child: LabelPill(
              label: categoryName,
              icon: IconRegistry.get(
                categoryIcon?.icon,
                fallback: AppIcons.category,
              ),
              color: categoryIcon?.accentColorFor(palette) ?? palette.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        MoneyText(
          amount,
          symbol: symbol,
          hideable: false,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: typeColor,
          ),
        ),
      ],
    ),
  );
}
