import 'package:flutter/material.dart';

import '../../molecules/list_row.dart';
import '../../molecules/progress_row.dart';
import '../../tokens/app_spacing.dart';
import '../money/money_text.dart';

/// One bar of an event ranking — who paid, top tags, a member's share
/// (replaces the summary tab's private `_barRow`):
///
///   (lead)  label                                   ฿1,200
///           ▓▓▓▓▓▓▓▓▓▓░░░░░░░░
///
/// [leading]: the avatar / icon (a [PersonMark], an icon tile, 28).
/// [share]: this row's ratio of the total (0–1) as a thin [ProgressRow] in
/// [color] (default primary). [amount] with [tone] (plain by default; signed
/// for a net position — + = they're owed). [onTap] / [dimmed] as [ListRow].
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

  /// The share bar's thickness.
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
