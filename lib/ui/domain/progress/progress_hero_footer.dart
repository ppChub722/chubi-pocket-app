import 'package:flutter/material.dart';

import '../../atoms/skeleton_box.dart';
import '../../molecules/progress_row.dart';
import '../../tokens/app_spacing.dart';
import '../money/money_text.dart';
import 'progress_tone.dart';

/// The footer of a progress entity's `HeaderCard` (a budget / goal hero; the
/// mockup's `.hero-foot`):
///
///   [caption]                    "ใช้ไปแล้ว"
///   ฿3,120                       the big [amount] (tone colour unless neutral)
///   [subCaption]                 "จาก ฿8,000 · เหลือ ฿4,880"
///   ▓▓▓▓▓▓▒▒▒░░░░░░░░░░░░        thick bar: [value] + [expected]
///   ● ใช้แล้ว 39%    ● คาดว่าจะใช้ +฿720     the legend
///
/// [legendUsed] / [legendExpected] are the caller's strings (the second dot
/// is the lighter shade; leave it null when there is no [expected]). [color]
/// is the bar colour (the entity's tint for [ProgressTone.neutral]).
class ProgressHeroFooter extends StatelessWidget {
  const ProgressHeroFooter({
    required this.amount,
    required this.value,
    this.caption,
    this.subCaption,
    this.expected,
    this.tone = ProgressTone.neutral,
    this.color,
    this.legendUsed,
    this.legendExpected,
    super.key,
  }) : skeleton = false;

  /// A loading placeholder with the same slots.
  const ProgressHeroFooter.skeleton({super.key})
    : amount = 0,
      value = 0,
      caption = null,
      subCaption = null,
      expected = null,
      tone = ProgressTone.neutral,
      color = null,
      legendUsed = null,
      legendExpected = null,
      skeleton = true;

  /// The big figure (money).
  final num amount;
  final String? caption;
  final String? subCaption;
  final double value;
  final double? expected;
  final ProgressTone tone;

  /// The bar colour for [ProgressTone.neutral] (the entity's tint).
  final Color? color;
  final String? legendUsed;
  final String? legendExpected;
  final bool skeleton;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (skeleton) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 80, height: 10),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: 140, height: 28),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: 180, height: 10),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 10, borderRadius: 10),
        ],
      );
    }
    final barColor = tone.resolve(context, entityTint: color);
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    Widget dot(Color c) => Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      decoration: ShapeDecoration(shape: const CircleBorder(), color: c),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null) Text(caption!, style: muted),
        MoneyText(
          amount,
          style: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: tone == ProgressTone.neutral ? null : barColor,
          ),
        ),
        if (subCaption != null) Text(subCaption!, style: muted, maxLines: 1),
        const SizedBox(height: AppSpacing.sm),
        ProgressRow(
          value: value,
          expected: expected,
          color: barColor,
          overColor: barColor,
          height: 10,
        ),
        if (legendUsed != null || legendExpected != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                if (legendUsed != null)
                  Expanded(
                    child: Row(
                      children: [
                        dot(barColor),
                        Flexible(
                          child: Text(
                            legendUsed!,
                            style: muted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (legendExpected != null)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        dot(barColor.withValues(alpha: 0.45)),
                        Flexible(
                          child: Text(
                            legendExpected!,
                            style: muted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
