import 'package:flutter/material.dart';

import '../../molecules/list_row.dart';
import '../../molecules/progress_row.dart';
import '../../tokens/app_spacing.dart';
import '../money/money_text.dart';

class PositionRow extends StatelessWidget {
  const PositionRow({
    required this.label,
    required this.amount,
    required this.share,
    this.leading,
    this.tone = MoneyTone.plain,
    this.symbol = '฿',
    this.color,
    this.onTap,
    this.dimmed = false,
    super.key,
  });

  static const double barHeight = 6;

  final String label;
  final num amount;
  final double share;
  final Widget? leading;
  final MoneyTone tone;
  final String symbol;
  final Color? color;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      leading: leading,
      onTap: onTap,
      dimmed: dimmed,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              MoneyText(amount, tone: tone, symbol: symbol),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ProgressRow(value: share, color: color, height: barHeight),
        ],
      ),
    );
  }
}
