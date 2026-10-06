import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import 'money_text.dart';

/// One labelled amount in a [SummaryStats] row.
class SummaryStat {
  const SummaryStat({
    required this.label,
    required this.amount,
    this.tone = MoneyTone.plain,
  });

  final String label;
  final num amount;
  final MoneyTone tone;
}

/// Row of labelled amounts — income · expense · net (dashboard summary,
/// account summary, filter summary strip, project totals).
///
/// [compact] renders a single-line strip ("รายจ่าย ฿x · รายรับ ฿y …")
/// for the top of filtered lists.
class SummaryStats extends StatelessWidget {
  const SummaryStats({required this.stats, this.compact = false, super.key});

  final List<SummaryStat> stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('·',
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              Text('${stats[i].label} ',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              MoneyText(
                stats[i].amount,
                tone: stats[i].tone,
                style: textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in stats)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label,
                  style: textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                MoneyText(
                  s.amount,
                  tone: s.tone,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
