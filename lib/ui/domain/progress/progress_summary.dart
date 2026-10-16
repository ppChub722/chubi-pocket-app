import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';
import '../money/money_text.dart';
import 'progress_tone.dart';

/// A progress SUMMARY with no icon (owner 2026-10-13): the budgets list
/// header ("this period, all budgets"), the goals list header, a goal hero
/// footer.
///
///   ฿12,400            the big money [amount]
///   caption            "ใช้ไปแล้ว จาก ฿20,000"
///   ▓▓▓▓▓▒▒▒░░░░░░░    [value] + [expected], clamped bar
///   label          62%  [label] left, [percentText] right (not clamped)
///   footnote           "เหลือ ฿7,600 · เกิน 1 งบ"
///
/// [tone] colours the bar (and the % unless neutral; neutral = [color], else
/// the primary colour).
class ProgressSummary extends StatelessWidget {
  const ProgressSummary({
    required this.amount,
    required this.value,
    this.caption,
    this.expected,
    this.tone = ProgressTone.neutral,
    this.color,
    this.label,
    this.percentText,
    this.footnote,
    super.key,
  }) : skeleton = false;

  /// A loading placeholder with the same slots.
  const ProgressSummary.skeleton({super.key})
    : amount = 0,
      value = 0,
      caption = null,
      expected = null,
      tone = ProgressTone.neutral,
      color = null,
      label = null,
      percentText = null,
      footnote = null,
      skeleton = true;

  /// The big figure (money).
  final num amount;
  final String? caption;
  final double value;
  final double? expected;
  final ProgressTone tone;

  /// The bar colour for [ProgressTone.neutral].
  final Color? color;
  final String? label;
  final String? percentText;
  final String? footnote;
  final bool skeleton;

  @override
  Widget build(BuildContext context) {
    if (skeleton) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: PpForgeSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 140, height: 28),
            SizedBox(height: PpForgeSpacing.xs),
            SkeletonBox(width: 180, height: 10),
            SizedBox(height: PpForgeSpacing.sm),
            SkeletonBox(height: 8, borderRadius: 8),
            SizedBox(height: PpForgeSpacing.xs),
            SkeletonBox(width: 120, height: 10),
          ],
        ),
      );
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final barColor = tone.resolve(context, entityTint: color);
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MoneyText(
          amount,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (caption != null) Text(caption!, style: muted),
        const SizedBox(height: PpForgeSpacing.sm),
        ProgressRow(
          value: value,
          expected: expected,
          color: barColor,
          overColor: barColor,
          label: label,
          trailing: percentText,
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.only(top: PpForgeSpacing.xs),
            child: Text(footnote!, style: muted),
          ),
      ],
    );
  }
}
