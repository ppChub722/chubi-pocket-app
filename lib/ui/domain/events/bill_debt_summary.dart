import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';

/// One person of a [BillDebtSummary]: who, their state with me before →
/// after the save ([state], null = not known yet) and what the save does
/// ([chip]: "เพิ่มหนี้ ฿300" / "ลดหนี้ ฿300" / "คืนแล้ว"; null = nothing).
class BillDebtLine {
  const BillDebtLine({
    required this.avatar,
    required this.name,
    this.state,
    this.chip,
    this.chipTone = AppChipTone.warning,
  });

  final Widget avatar;
  final String name;
  final String? state;
  final String? chip;
  final AppChipTone chipTone;
}

/// 0.4.1-2 SA5 — the bill form's debt summary before saving: one line per
/// person my book's debts with move (from the BE preview), plus the people
/// marked "คืนแล้ว". [loading] dims it while a newer preview is on its way.
class BillDebtSummary extends StatelessWidget {
  const BillDebtSummary({required this.lines, this.loading = false, super.key});

  final List<BillDebtLine> lines;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget line(BillDebtLine p) {
      final state = p.state;
      final chip = p.chip;
      return Row(
        children: [
          p.avatar,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (state != null)
                  Text(
                    state,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (chip != null)
            AppChip(
              label: chip,
              tone: p.chipTone,
              selected: true,
              size: ChipSize.mini,
            ),
        ],
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: loading ? 0.6 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, p) in lines.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            line(p),
          ],
        ],
      ),
    );
  }
}
