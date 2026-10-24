import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import 'net_balance.dart';

/// Quick create's debt mode (owner 2026-10-21, mock "หนี้: 2 chip +
/// ลูกศรสลับทิศ"): two chips where the tx mode has รายจ่าย / รายรับ —
/// record a debt | settle it. The words and the colour follow the direction
/// ([towardMe]: them → me = [รอรับ | รับคืน], green; me → them = [รอจ่าย |
/// จ่ายคืน], red); the arrow between the cards swaps it. [caption] under the
/// chips says who pays whom back.
class DebtModeChips extends StatelessWidget {
  const DebtModeChips({
    required this.towardMe,
    required this.settle,
    required this.recordLabel,
    required this.settleLabel,
    required this.onChanged,
    this.caption,
    super.key,
  });

  final bool towardMe;

  /// The settle chip is the one picked.
  final bool settle;
  final String recordLabel;
  final String settleLabel;

  /// true = settle; null = fixed (no switching).
  final ValueChanged<bool>? onChanged;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final color = debtStateColor(context, owedToMe: towardMe);
    final change = onChanged;
    Widget chip(String label, IconData icon, bool isSettle) {
      final selected = isSettle == settle;
      final dashed = change != null && !selected;
      return AppChip(
        key: ValueKey(isSettle ? 'debtModeSettle' : 'debtModeRecord'),
        label: label,
        icon: dashed ? null : icon,
        color: color,
        selected: selected,
        dashed: dashed,
        onTap: dashed ? () => change(isSettle) : null,
      );
    }

    final caption = this.caption;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            chip(recordLabel, AppIcons.debt, false),
            chip(settleLabel, AppIcons.cash, true),
          ],
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              caption,
              key: const ValueKey('debtModeCaption'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
