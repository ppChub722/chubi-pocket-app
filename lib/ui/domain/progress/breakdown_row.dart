import 'package:flutter/material.dart';

import '../../molecules/progress_row.dart';
import '../../tokens/app_spacing.dart';
import '../money/money_text.dart';

/// One line of a breakdown ("by source", "by sub-category", a goal's
/// "wallet · share"; the mockup's `.brk`):
///
///   [leading] label  count caption                        ฿2,460
///   ▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
///
/// - [leading]: an icon tile, a `SourceChip`, anything small.
/// - [caption]: the muted count after the label ("18 รายการ").
/// - amount: [amount] (money) or [amountText] (a caller string); with
///   [expected] true it is muted and prefixed "+" — "still to come" (a
///   recurring item ahead, an unconfirmed draft).
/// - the mini bar: [value] = this row's share of the whole (0..1), drawn
///   solid; with [expected] true it is drawn as the lighter striped segment
///   instead. [color] is the bar colour (the entity's tint). No [value] = no
///   bar (a plain "icon · name · amount" row).
/// - [onTap].
class BreakdownRow extends StatelessWidget {
  const BreakdownRow({
    required this.label,
    this.leading,
    this.caption,
    this.amount,
    this.amountText,
    this.expected = false,
    this.value,
    this.color,
    this.onTap,
    super.key,
  });

  final String label;
  final Widget? leading;
  final String? caption;
  final num? amount;
  final String? amountText;

  /// "Still to come": muted amount with a "+", striped bar.
  final bool expected;

  /// Share of the whole, 0..1 (null = no bar).
  final double? value;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final amountStyle = text.bodyMedium?.copyWith(
      fontWeight: expected ? FontWeight.w400 : FontWeight.w700,
      color: expected ? scheme.onSurfaceVariant : null,
    );
    final Widget? amountWidget = amount != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expected) Text('+', style: amountStyle),
              MoneyText(amount!, style: amountStyle),
            ],
          )
        : amountText != null
        ? Text(
            expected ? '+$amountText' : amountText!,
            style: amountStyle,
            maxLines: 1,
          )
        : null;
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PpForgeSpacing.lg,
        vertical: PpForgeSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: PpForgeSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(width: PpForgeSpacing.sm),
                Text(
                  caption!,
                  maxLines: 1,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              ?amountWidget,
            ],
          ),
          if (value != null) ...[
            const SizedBox(height: PpForgeSpacing.xs),
            ProgressRow(
              value: expected ? 0 : value!,
              expected: expected ? value : null,
              color: color,
              overColor: color,
              height: 6,
            ),
          ],
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}
