import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/scheduled_enums.dart';
import '../../domain/scheduled_transaction.dart';

/// Tappable list-row card for a scheduled entry.
///
/// Shows: icon · name · variant pill (Recurring/Installment/Loan) ·
/// next billing date · amount. For installments, also shows
/// `remaining/total` so the user sees how many payments are left.
class ScheduledCard extends StatelessWidget {
  const ScheduledCard({super.key, required this.entry, this.onTap});

  final ScheduledTransaction entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = entry.iconCode.tintFor(palette, fallback: scheme.primary);
    final amountColor = entry.type == ScheduledTransactionType.income
        ? palette.income
        : null;
    final desc = entry.description?.trim();

    return AppCard(
      style: AppCardStyle.bordered,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          IconDisplay(
            type: IconType.category,
            size: 44,
            iconCode: entry.iconCode,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        entry.name,
                        role: AppTextRole.title,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppChip(
                      label: entry.isLoan
                          ? l.scheduledVariantLoan
                          : entry.isInstallment
                          ? l.scheduledVariantInstallment
                          : l.scheduledVariantRecurring,
                      tone: AppChipTone.neutral,
                      selected: true,
                      size: ChipSize.chip,
                    ),
                  ],
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(desc, role: AppTextRole.caption, maxLines: 1),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    AppIcon(
                      AppIcons.date,
                      size: AppIconSize.sm,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppText(
                      l.scheduledNextDue(entry.nextBillingDate),
                      role: AppTextRole.caption,
                    ),
                    if (entry.isInstallment &&
                        entry.totalInstallments != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      AppText(
                        l.scheduledInstallmentsLeft(
                          entry.remainingInstallments ?? 0,
                          entry.totalInstallments!,
                        ),
                        role: AppTextRole.caption,
                        color: accent,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          MoneyText(
            entry.amount,
            style: AppTypography.of(
              context,
              AppTextRole.money,
            )?.copyWith(color: amountColor ?? scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
