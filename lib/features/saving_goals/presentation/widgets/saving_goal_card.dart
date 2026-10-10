import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/saving_goal.dart';

/// Saving goals list card: icon · name · description (when set) · linked
/// wallet · allocation % · progress "฿x จาก ฿y" (honours 👁) · completed
/// badge.
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
    final accent = goal.iconCode?.accentColorFor(palette) ?? palette.primary;
    final wallet = goal.linkedAccount?.name;
    final desc = goal.description?.trim() ?? '';
    final secondary = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onIconTap,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (desc.isNotEmpty)
                          Text(
                            desc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: secondary,
                          ),
                        if (wallet != null)
                          Text(
                            wallet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: secondary,
                          ),
                      ],
                    ),
                  ),
                  AppBadge(label: '${goal.allocationPct.toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressRow(
                value: goal.progressPct / 100,
                color: accent,
                label: l.savingGoalProgressLine(
                  moneyString(context, goal.currentAmount),
                  moneyString(context, goal.targetAmount),
                ),
                trailing: '${goal.progressPct.toStringAsFixed(0)}%',
              ),
              if (goal.isCompleted) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppBadge(
                    label: l.savingGoalCompletedLabel,
                    icon: AppIcons.success,
                    tone: Tone.success,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
