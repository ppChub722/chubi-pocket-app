import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import 'net_balance.dart';

enum DebtSummaryTone { owedToMe, iOwe, cleared, warn }

/// Quick create's debt summary (owner 2026-10-23): ONE line under the switch,
/// above the tag row — what the balance with this person will be after
/// saving. "[label] words" on the left, the new amount on the right in the
/// side's colour; green = they owe me, red = I owe, brand = cleared, error =
/// the side flips. All words come in ready.
class DebtSummaryRow extends StatelessWidget {
  const DebtSummaryRow({
    required this.words,
    required this.tone,
    this.label,
    this.amount,
    super.key,
  });

  /// "Chalee ต้องคืนฉัน".
  final String words;

  /// "หลังบันทึก", muted, in front of [words].
  final String? label;

  /// "฿2,464"; null when cleared.
  final String? amount;
  final DebtSummaryTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = switch (tone) {
      DebtSummaryTone.owedToMe => debtStateColor(context, owedToMe: true),
      DebtSummaryTone.iOwe => debtStateColor(context, owedToMe: false),
      DebtSummaryTone.cleared => scheme.primary,
      DebtSummaryTone.warn => scheme.error,
    };
    final icon = switch (tone) {
      DebtSummaryTone.cleared => AppIcons.success,
      DebtSummaryTone.warn => AppIcons.warning,
      _ => AppIcons.debt,
    };
    final label = this.label;
    final amount = this.amount;
    return DecoratedBox(
      key: const ValueKey('debtSummary'),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (label != null)
                      TextSpan(
                        text: '$label  ',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    TextSpan(
                      text: words,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium,
              ),
            ),
            if (amount != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                amount,
                style: text.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
