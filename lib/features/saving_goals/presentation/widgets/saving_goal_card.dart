import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
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
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = goal.iconCode.tintFor(palette);
    final wallet = goal.linkedAccount?.name;
    final desc = goal.description?.trim() ?? '';
    return AppCard(
      onTap: onTap,
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
                    AppText(goal.name, role: AppTextRole.title, maxLines: 1),
                    if (desc.isNotEmpty)
                      AppText(desc, role: AppTextRole.caption, maxLines: 1),
                    if (wallet != null)
                      AppText(wallet, role: AppTextRole.caption, maxLines: 1),
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
              child: AppChip(
                label: l.savingGoalCompletedLabel,
                icon: AppIcons.success,
                tone: AppChipTone.success,
                selected: true,
                size: ChipSize.chip,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
