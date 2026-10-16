import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../domain/budget.dart';
import 'budget_labels.dart';

/// The budgets list's summary card (owner 2026-10-16): the total used over the
/// total limit, one bar, the remaining + percent, and four tappable health
/// tiles (all / normal / near / over) that filter the list by health.
class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    required this.summary,
    required this.health,
    required this.onHealth,
    required this.action,
    super.key,
  });

  final BudgetListSummary summary;
  final BudgetHealth health;
  final ValueChanged<BudgetHealth> onHealth;

  /// The 🔍 [ToolbarToggleButton].
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final s = summary;
    final ratio = s.totalLimit <= 0 ? 0.0 : s.totalUsed / s.totalLimit;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CaptionRow(label: l.bgSummaryUsedCaption, action: action),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: budgetRowMoney(context, s.totalUsed),
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text:
                      '  ${l.bgHeroOfLimit(budgetRowMoney(context, s.totalLimit))}',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressRow(
            value: ratio,
            color: ProgressTone.normal.resolve(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.bgSummaryRemaining(
                    budgetRowMoney(context, s.totalRemaining),
                  ),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${s.usedPct}%',
                key: const ValueKey('budgetSummaryPct'),
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final t in [
                (BudgetHealth.all, l.bgTileAll, s.countAll, null),
                (BudgetHealth.normal, l.bgTileOk, s.countOk, palette.success),
                (BudgetHealth.near, l.bgStatWarn, s.countNear, palette.warning),
                (BudgetHealth.over, l.bgStatOver, s.countOver, palette.error),
              ]) ...[
                if (t.$1 != BudgetHealth.all)
                  const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _HealthTile(
                    key: ValueKey('budgetTile_${t.$1.name}'),
                    label: t.$2,
                    count: t.$3,
                    color: t.$4 ?? scheme.onSurfaceVariant,
                    selected: health == t.$1,
                    onTap: () => onHealth(t.$1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A card with only the caption row (+ 🔍): for the other statuses and an empty
/// active list, so the toolbar stays reachable.
class BudgetCompactCard extends StatelessWidget {
  const BudgetCompactCard({
    required this.label,
    required this.action,
    super.key,
  });

  final String label;
  final Widget action;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: _CaptionRow(label: label, action: action),
  );
}

class _CaptionRow extends StatelessWidget {
  const _CaptionRow({required this.label, required this.action});

  final String label;
  final Widget action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const MoneyVisibilityToggle(),
      const SizedBox(width: AppSpacing.xs),
      action,
    ],
  );
}

/// One tinted tile (count over label), ringed when selected.
class _HealthTile extends StatelessWidget {
  const _HealthTile({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: SelectableFrame(
        selected: selected,
        color: scheme.primary,
        radius: AppRadius.md,
        gap: 2,
        child: AppCard(
          style: AppCardStyle.tinted,
          color: color,
          radius: BorderRadius.circular(AppRadius.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$count',
                style: text.titleMedium?.copyWith(
                  color: color,
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
