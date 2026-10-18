import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_card.dart';
import '../../atoms/app_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';

@immutable
class NextOccurrenceAction {
  const NextOccurrenceAction({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onTap;

  final bool primary;
}

class NextOccurrenceCard extends StatelessWidget {
  const NextOccurrenceCard({
    required this.title,
    required this.amount,
    this.caption,
    this.chips = const [],
    this.actions = const [],
    this.onTap,
    super.key,
  });

  final String title;

  final Widget amount;

  final String? caption;

  final List<Widget> chips;
  final List<NextOccurrenceAction> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      style: AppCardStyle.accent,
      color: scheme.primary,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        caption!,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: chips,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DefaultTextStyle.merge(
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                child: amount,
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final (i, a) in actions.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: a.label,
                      expand: true,
                      variant: a.primary
                          ? AppButtonVariant.primary
                          : AppButtonVariant.outlined,
                      submits: true,
                      onPressed: a.onTap,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum OccurrenceDateKind { normal, edited, skipped }

@immutable
class OccurrenceDate {
  const OccurrenceDate({
    required this.label,
    this.kind = OccurrenceDateKind.normal,
    this.onTap,
  });

  final String label;
  final OccurrenceDateKind kind;
  final VoidCallback? onTap;
}

class OccurrenceDates extends StatelessWidget {
  const OccurrenceDates({
    required this.title,
    required this.dates,
    this.moreLabel,
    this.onMore,
    super.key,
  });

  final String title;
  final List<OccurrenceDate> dates;

  final String? moreLabel;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final d in dates)
              switch (d.kind) {
                OccurrenceDateKind.skipped => _Struck(date: d),
                _ => AppChip(
                  label: d.label,
                  size: ChipSize.chip,
                  selected: d.kind == OccurrenceDateKind.edited,
                  color: d.kind == OccurrenceDateKind.edited
                      ? palette.warning
                      : null,
                  onTap: d.onTap,
                ),
              },
            if (moreLabel != null)
              AppChip(
                label: moreLabel!,
                size: ChipSize.chip,
                tone: AppChipTone.primary,
                onTap: onMore,
              ),
          ],
        ),
      ],
    );
  }
}

class _Struck extends StatelessWidget {
  const _Struck({required this.date});

  final OccurrenceDate date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: date.onTap,
      borderRadius: BorderRadius.circular(ChipSize.chip.heightOf(context)),
      child: Container(
        height: ChipSize.chip.heightOf(context),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChipSize.chip.heightOf(context)),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          date.label,
          style: text.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}
