import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../domain/scheduled_enums.dart';
import '../../domain/scheduled_transaction.dart';

/// Tappable list-row card for a scheduled entry.
///
/// Shows: icon · name · variant pill (Recurring/Installment/Loan) ·
/// next billing date · amount. For installments, also shows
/// `remaining/total` so the user sees how many payments are left.
class ScheduledCard extends StatelessWidget {
  const ScheduledCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  final ScheduledTransaction entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = entry.iconCode?.accentColorFor(palette) ?? scheme.primary;
    final amountColor =
        entry.type == ScheduledTransactionType.income ? Colors.green : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
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
                        _VariantPill(entry: entry),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l.scheduledNextDue(entry.nextBillingDate),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
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
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: accent),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                CurrencyFormatter.format(entry.amount),
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

class _VariantPill extends StatelessWidget {
  const _VariantPill({required this.entry});
  final ScheduledTransaction entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final label = entry.isLoan
        ? l.scheduledVariantLoan
        : entry.isInstallment
            ? l.scheduledVariantInstallment
            : l.scheduledVariantRecurring;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
