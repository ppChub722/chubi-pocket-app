import 'package:flutter/material.dart';

import '../../atoms/app_icon.dart';
import '../../atoms/app_icon_button.dart';
import '../../atoms/ui_config.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import '../../atoms/busy_scope.dart';

/// Which flow box is picked (a filter on the list below the hero).
enum HeroFlowSelection { none, income, expense }

/// A month's money in and out across the hero: [‹] [in] [out] [›]. The
/// arrows step the month; a null [onNext] fades it (this month has no next).
/// Tapping a box picks it, as a filter on the list below.
class HeroFlowRow extends StatelessWidget {
  const HeroFlowRow({
    required this.incomeLabel,
    required this.expenseLabel,
    required this.income,
    required this.expense,
    this.onPrev,
    this.onNext,
    this.onTapIncome,
    this.onTapExpense,
    this.selected = HeroFlowSelection.none,
    this.prevTooltip,
    this.nextTooltip,
    super.key,
  });

  /// e.g. "เงินเข้า ต.ค.": the label carries the month.
  final String incomeLabel;
  final String expenseLabel;
  final String income;
  final String expense;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onTapIncome;
  final VoidCallback? onTapExpense;
  final HeroFlowSelection selected;

  /// Null = the kit's "previous" / "next".
  final String? prevTooltip;
  final String? nextTooltip;

  static const double _step = 28;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    final strings = UiConfig.stringsOf(context);
    return Row(
      children: [
        AppIconButton(
          key: const ValueKey('heroFlowPrev'),
          icon: AppIcons.chevronLeft,
          size: _step,
          tooltip: prevTooltip ?? strings.periodPrev,
          onPressed: onPrev,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FlowBox(
            key: const ValueKey('heroFlowIncome'),
            icon: AppIcons.flowIn,
            label: incomeLabel,
            amount: income,
            color: hero?.success ?? scheme.primary,
            selected: selected == HeroFlowSelection.income,
            onTap: onTapIncome,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FlowBox(
            key: const ValueKey('heroFlowExpense'),
            icon: AppIcons.flowOut,
            label: expenseLabel,
            amount: expense,
            color: hero?.danger ?? scheme.error,
            selected: selected == HeroFlowSelection.expense,
            onTap: onTapExpense,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButton(
          key: const ValueKey('heroFlowNext'),
          icon: AppIcons.chevronRight,
          size: _step,
          tooltip: nextTooltip ?? strings.periodNext,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _FlowBox extends StatelessWidget {
  const _FlowBox({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String amount;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hero = HeroColors.maybeOf(context);
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: selected ? color.withValues(alpha: 0.1) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected
                ? color.withValues(alpha: 0.6)
                : hero?.line ?? scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: BusyLock(
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + AppSpacing.xxs,
                vertical: AppSpacing.xs + AppSpacing.xxs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: AppIcon(icon, size: 12, color: color),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 1),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(
                            color: hero?.muted ?? scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      amount,
                      maxLines: 1,
                      style: text.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
