import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../molecules/progress_row.dart';
import '../../molecules/status_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../../tokens/tone.dart';
import '../icons/icon_code.dart';
import '../icons/icon_code_widget.dart';

/// A saving goal in a list: the name with its status tag, a line under it
/// (when it is due), the amount on the right with a small line under it, then
/// the bar (no bar for a goal without a target).
class SavingGoalRow extends StatelessWidget {
  const SavingGoalRow({
    required this.title,
    required this.amountText,
    this.value,
    this.iconCode,
    this.fallbackIcon,
    this.caption,
    this.trailing,
    this.trailingTone = Tone.neutral,
    this.trailingCaption,
    this.badge,
    this.badgeTone = Tone.success,
    this.color,
    this.marker,
    this.markerBubble,
    this.dimmed = false,
    this.onTap,
    super.key,
  });

  final String title;

  final double? value;

  final String amountText;
  final IconCode? iconCode;
  final IconData? fallbackIcon;

  /// Under the name: only what the goal has ("ถึงเป้า ก.ค. 2027 | ช้า 6 เดือน").
  final String? caption;

  final String? trailing;
  final Tone trailingTone;

  /// Small, under [trailing] ("เดือนนี้ ฿234 / ฿703").
  final String? trailingCaption;

  final String? badge;
  final Tone badgeTone;

  /// The bar's color; null = the goal's own tint.
  final Color? color;

  /// Where the goal should be by now, with [markerBubble] over it.
  final double? marker;
  final String? markerBubble;
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
            fallbackIcon: fallbackIcon ?? AppIcons.savings,
            fallbackColor: tint,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: AppSpacing.xs),
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
                          if (caption != null)
                            Text(
                              caption!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            trailing!,
                            maxLines: 1,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: trailingTone.color(context),
                            ),
                          ),
                          if (trailingCaption != null)
                            Text(
                              trailingCaption!,
                              maxLines: 1,
                              style: text.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (value != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ProgressRow(
                    value: value!,
                    color: color ?? tint,
                    height: 9,
                    marker: marker,
                    markerBubble: markerBubble,
                  ),
                ],
                // An empty amountText leaves the line out.
                if (amountText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    amountText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
