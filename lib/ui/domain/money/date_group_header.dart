import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../../atoms/list_break.dart';
import 'money_text.dart';

class DateGroupHeader extends StatelessWidget implements ListBreak {
  const DateGroupHeader({
    required this.label,
    this.total,
    this.note,
    this.noteColor,
    super.key,
  });

  final String label;

  final num? total;

  /// Words at the end instead of [total] (a debt day: "เพิ่ม ฿70" /
  /// "ลดลง ฿400"), in [noteColor].
  final String? note;
  final Color? noteColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant);
    // Over a card of rows the label lines up with a card title (md in from
    // the edge); the total stays over the rows' amounts.
    final carded = CardedListBreak.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        carded ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          if (note != null)
            Text(
              note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: noteColor ?? scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (total != null)
            MoneyText(total!, tone: MoneyTone.signed, style: style),
        ],
      ),
    );
  }
}
