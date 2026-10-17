import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_card.dart';
import '../../atoms/app_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';

/// One action of a [NextOccurrenceCard] (แก้ยอด / เลื่อนวัน / ข้าม).
@immutable
class NextOccurrenceAction {
  const NextOccurrenceAction({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// The main action (filled) — ใส่ยอด on a reminder with no amount.
  final bool primary;
}

/// The NEXT occurrence of a recurring, prominent (reference "รายการประจำ" ›
/// ล่วงหน้า):
///
///   งวดถัดไป · อีก 30 วัน                         −฿3,023
///   จะขึ้นร่างใน pending วันนั้น
///   [แก้ยอด] [เลื่อนวัน] [ข้าม]
///
/// Words come from the caller; the amount is a widget (a `MoneyText`, or
/// the "รอใส่ยอด" text of a reminder with no amount).
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

  /// "งวดถัดไป · อีก 30 วัน".
  final String title;

  /// The amount (or its absence) on the right.
  final Widget amount;

  /// A small line under the title.
  final String? caption;

  /// Mini chips after the caption ("แก้แล้ว", "งวดที่ 4/10").
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

/// How one date of [OccurrenceDates] looks.
enum OccurrenceDateKind {
  normal,

  /// Edited on its own (amber).
  edited,

  /// Skipped (struck through, muted).
  skipped,
}

/// One date chip of [OccurrenceDates].
@immutable
class OccurrenceDate {
  const OccurrenceDate({
    required this.label,
    this.kind = OccurrenceDateKind.normal,
    this.onTap,
  });

  /// "16 ธ.ค." (+ " · ฿3,500" when edited, + " · ข้าม" when skipped).
  final String label;
  final OccurrenceDateKind kind;
  final VoidCallback? onTap;
}

/// "ต่อจากนั้น · อีก 11 งวด" + the remaining occurrences as date chips
/// (edited ones amber, skipped struck through) and a "+6 ›" chip. No row of
/// twelve identical lines.
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

  /// "+6 ›": the chip that shows the rest; null = none.
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
      borderRadius: BorderRadius.circular(ChipSize.chip.height),
      child: Container(
        height: ChipSize.chip.height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChipSize.chip.height),
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
