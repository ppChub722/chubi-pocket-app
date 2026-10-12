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
    final accent = entry.iconCode?.accentColorFor(palette) ?? scheme.primary;
    final amountColor = entry.type == ScheduledTransactionType.income
        ? palette.income
        : null;
    final desc = entry.description?.trim();

    return AppCard(
      style: AppCardStyle.bordered,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
                          child: Text(
                            entry.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppIcon(
                          AppIcons.date,
                          size: AppIconSize.sm,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l.scheduledNextDue(entry.nextBillingDate),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (entry.isInstallment &&
                            entry.totalInstallments != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            l.scheduledInstallmentsLeft(
                              entry.remainingInstallments ?? 0,
                              entry.totalInstallments!,
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: accent),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: amountColor ?? scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
