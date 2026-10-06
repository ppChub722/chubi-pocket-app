import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';

/// How a [TypeIndicator] renders.
enum TypeIndicatorVariant {
  /// Soft colour-tinted pill: `[− รายจ่าย]` / `[+ รายรับ]`.
  pill,

  /// Just the `+` / `−` glyph in the flow colour — for prefixing amounts.
  sign,
}

/// Universal income/expense indicator. Expense reads red with a `−`;
/// income reads green with a `+` — the sign convention money UIs share,
/// so it's legible the moment you glance at it.
///
/// Domain-agnostic: takes a plain [isIncome] flag (callers map their own
/// `CategoryType` / `TransactionType`), so it lives in `shared` without
/// depending on any feature. Reuse anywhere a row is income-or-expense:
/// category type, transaction amounts, budgets, reports.
class TypeIndicator extends StatelessWidget {
  const TypeIndicator({
    required this.isIncome,
    this.variant = TypeIndicatorVariant.pill,
    this.label,
    super.key,
  });

  final bool isIncome;
  final TypeIndicatorVariant variant;

  /// Overrides the pill's text. Defaults to the localized income/expense
  /// label. Ignored by [TypeIndicatorVariant.sign].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final color = isIncome ? palette.income : palette.expense;
    final signIcon = isIncome ? AppIcons.income : AppIcons.expense;

    switch (variant) {
      case TypeIndicatorVariant.sign:
        return Icon(signIcon, size: 18, color: color);
      case TypeIndicatorVariant.pill:
        final l = AppLocalizations.of(context)!;
        final text =
            label ?? (isIncome ? l.categoryTypeIncome : l.categoryTypeExpense);
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(signIcon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
    }
  }
}
