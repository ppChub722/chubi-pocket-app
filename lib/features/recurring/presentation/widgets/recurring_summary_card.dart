import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/recurring_summary.dart';

/// The recurring list's summary (the Debts card's look): "per month" with the
/// 👁 toggle, two tinted boxes (pay / receive) and the next due item. A null
/// [summary] (absent) shows "—" in the boxes.
class RecurringSummaryCard extends StatelessWidget {
  const RecurringSummaryCard({
    required this.summary,
    this.margin = EdgeInsets.zero,
    this.action,
    super.key,
  });

  /// The top-right action slot after the 👁 (the 🔍 toolbar toggle).
  final Widget? action;
  final RecurringSummary? summary;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final s = summary;
    return AppCard(
      margin: margin,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.recurringSummaryMonth,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const MoneyVisibilityToggle(),
              if (action != null) ...[
                const SizedBox(width: AppSpacing.xs),
                action!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Box(
                  label: l.recurringSummaryPay,
                  amount: s?.monthPay,
                  color: palette.expense,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Box(
                  label: l.recurringSummaryReceive,
                  amount: s?.monthReceive,
                  color: palette.income,
                ),
              ),
            ],
          ),
          if (s?.nextDate != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l.recurringSummaryNext} · ${s!.nextName ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DueText(date: s.nextDate!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.label, required this.amount, required this.color});

  final String label;
  final num? amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final style = textTheme.titleMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
    );
    return AppCard(
      style: AppCardStyle.tinted,
      color: color,
      radius: BorderRadius.circular(AppRadius.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          amount == null
              ? Text('—', style: style)
              : MoneyText(amount!.abs(), style: style),
        ],
      ),
    );
  }
}
