import 'package:flutter/material.dart';

import '../../molecules/progress_row.dart';
import '../../tokens/app_spacing.dart';
import '../money/money_text.dart';

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

  final bool expected;

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
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
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
                const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.xs),
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
