import 'package:flutter/material.dart';

import '../../molecules/app_list_row.dart';
import '../../molecules/progress_row.dart';
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
    return AppListRow(
      leading: leading ?? const SizedBox.shrink(),
      title: label,
      trailing: ListRowTrailing.value(
        MoneyText(amount, tone: tone, symbol: symbol),
      ),
      footer: ProgressRow(value: share, color: color, height: barHeight),
      onTap: onTap,
      dimmed: dimmed,
    );
  }
}
