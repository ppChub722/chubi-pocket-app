import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../molecules/progress_row.dart';
import '../../molecules/status_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../../tokens/tone.dart';
import '../icons/icon_code.dart';
import '../icons/icon_code_widget.dart';

class SavingGoalRow extends StatelessWidget {
  const SavingGoalRow({
    required this.title,
    required this.amountText,
    this.value,
    this.iconCode,
    this.fallbackIcon,
    this.trailing,
    this.trailingTone = Tone.neutral,
    this.badge,
    this.badgeTone = Tone.success,
    this.dimmed = false,
    this.onTap,
    super.key,
  });

  final String title;

  final double? value;

  final String amountText;
  final IconCode? iconCode;
  final IconData? fallbackIcon;

  final String? trailing;
  final Tone trailingTone;

  final String? badge;
  final Tone badgeTone;
  final bool dimmed;
  final VoidCallback? onTap;

  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final tint = iconCode.tintFor(palette);
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCodeWidget(
            iconCode: iconCode,
            size: _tile,
            displayMode: IconDisplayMode.compact,
            fallbackIcon: fallbackIcon ?? Icons.savings_outlined,
            fallbackColor: tint,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        trailing!,
                        maxLines: 1,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: trailingTone.color(context),
                        ),
                      ),
                    ],
                  ],
                ),
                if (value != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ProgressRow(value: value!, color: tint, height: 9),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        amountText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: StatusChip.tone(
                          label: badge!,
                          tone: AppChipTone.fromTone(badgeTone),
                          size: ChipSize.mini,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final row = Material(
      color: Colors.transparent,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}
