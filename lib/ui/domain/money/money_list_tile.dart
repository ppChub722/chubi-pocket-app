import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../../atoms/list_break.dart';
import 'money_text.dart';

class MoneyListTile extends StatelessWidget {
  const MoneyListTile({
    required this.leading,
    required this.title,
    required this.amount,
    this.subtitle,
    this.footer,
    this.tone = MoneyTone.signed,
    this.amountCaption,
    this.onTap,
    this.dimmed = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    super.key,
  });

  final Widget leading;
  final String title;

  final Widget? subtitle;

  final Widget? footer;
  final num amount;
  final MoneyTone tone;

  final String? amountCaption;
  final VoidCallback? onTap;

  final bool dimmed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tile = InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge,
                  ),
                  if (subtitle != null)
                    DefaultTextStyle.merge(
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: IconTheme.merge(
                        data: IconThemeData(
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        child: subtitle!,
                      ),
                    ),
                  if (footer != null)
                    DefaultTextStyle.merge(
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: footer!,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                MoneyText(
                  amount,
                  tone: tone,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (amountCaption != null)
                  Text(
                    amountCaption!,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: tile) : tile;
  }
}

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
