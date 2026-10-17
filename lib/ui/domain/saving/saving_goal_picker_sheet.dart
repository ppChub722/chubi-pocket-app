import 'package:flutter/material.dart';

import '../../atoms/dashed_rect_border.dart';
import '../../organisms/app_sheet.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

class SavingGoalPick {
  const SavingGoalPick({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.amountText,
    this.targetText,
    this.progress,
    this.caption,
  });

  final String? id;
  final String name;
  final IconData icon;
  final Color color;
  final String? amountText;
  final String? targetText;
  final double? progress;
  final String? caption;
}

typedef SavingGoalChoice = ({String? id});

Future<SavingGoalChoice?> showSavingGoalPickerSheet(
  BuildContext context, {
  required String title,
  required List<SavingGoalPick> items,
  required String? selectedId,
}) {
  return showAppSheet<SavingGoalChoice>(
    context,
    title: title,
    builder: (ctx) => LayoutBuilder(
      builder: (context, box) {
        // Two columns inside the side padding (the card width must be taken
        // AFTER it, or the second card wraps onto its own line).
        final w = ((box.maxWidth - AppSpacing.lg * 2 - AppSpacing.sm) / 2)
            .floorToDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final g in items)
                SizedBox(
                  width: w,
                  child: SavingGoalCard(
                    pick: g,
                    selected: g.id == selectedId,
                    onTap: () => Navigator.of(ctx).pop((id: g.id)),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class SavingGoalCard extends StatelessWidget {
  const SavingGoalCard({
    required this.pick,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SavingGoalPick pick;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.md);
    final amount = pick.amountText;
    final target = pick.targetText;
    final progress = pick.progress;
    Widget card = Material(
      color: selected
          ? pick.color.withValues(alpha: 0.12)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: selected
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: pick.color.withValues(alpha: 0.2),
                        child: Icon(pick.icon, size: 16, color: pick.color),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          pick.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (amount != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text.rich(
                      TextSpan(
                        text: amount,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        children: [
                          if (target != null)
                            TextSpan(
                              text: ' / $target',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (progress != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        color: pick.color,
                        backgroundColor: scheme.outlineVariant,
                      ),
                    ),
                  ],
                  if (pick.caption != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      pick.caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md - 3),
                        border: Border.all(color: pick.color),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (selected) {
      card = DashedRectBorder(
        color: pick.color,
        strokeWidth: 1,
        dashLength: 4,
        gapLength: 3,
        borderRadius: Radius.circular(AppRadius.md),
        child: card,
      );
    }
    return Semantics(button: true, selected: selected, child: card);
  }
}
