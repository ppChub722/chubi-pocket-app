import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// Progress bar + caption — budgets, saving goals, debt repayment, credit
/// utilisation, project plan vs actual.
///
/// [value] is a ratio (0–1); above 1 the bar fills and turns [overColor]
/// (defaults to the error colour) to flag over-budget / over-limit.
class ProgressRow extends StatelessWidget {
  const ProgressRow({
    required this.value,
    this.label,
    this.trailing,
    this.color,
    this.overColor,
    this.height = 8,
    super.key,
  });

  final double value;

  /// Left caption under the bar ("คืนแล้ว ฿300 จาก ฿500").
  final String? label;

  /// Right caption under the bar ("60%", "เหลือ ฿200").
  final String? trailing;
  final Color? color;
  final Color? overColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = value > 1;
    final barColor = over
        ? (overColor ?? scheme.error)
        : (color ?? scheme.primary);
    final captionStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: height,
              color: barColor,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        if (label != null || trailing != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    style: captionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: captionStyle?.copyWith(
                    color: over ? barColor : null,
                    fontWeight: over ? FontWeight.w600 : null,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
