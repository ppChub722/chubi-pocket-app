import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../domain/saving_goal.dart';

/// Tappable card row for the saving goals list.
///
/// Anatomy per design-sheet §8.3: icon · name · progress bar · current /
/// target · % allocation badge. The card uses `surface-container` and
/// adopts the goal's icon accent for the bar color.
///
/// Phase 1c reuses [IconType.account] for saving goals (per
/// `phase1c/overview.md` cross-cutting decision) — we'll split to a
/// dedicated `IconType.savingGoal` in Phase 2 polish.
class SavingGoalCard extends StatelessWidget {
  const SavingGoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onIconTap,
  });

  final SavingGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent =
        goal.iconCode?.accentColorFor(palette) ?? scheme.primary;
    final progress = (goal.progressPct / 100).clamp(0.0, 1.0);
    final accountName = goal.linkedAccount?.name;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: onIconTap,
                    borderRadius: BorderRadius.circular(28),
                    child: IconDisplay(
                      type: IconType.account,
                      size: 44,
                      iconCode: goal.iconCode,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (accountName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            accountName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _AllocationBadge(pct: goal.allocationPct),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.savingGoalProgressLine(
                      CurrencyFormatter.format(goal.currentAmount),
                      CurrencyFormatter.format(goal.targetAmount),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${goal.progressPct.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              if (goal.isCompleted) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l.savingGoalCompletedLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accent,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AllocationBadge extends StatelessWidget {
  const _AllocationBadge({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        '${pct.toStringAsFixed(0)}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
