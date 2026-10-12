import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import 'money_text.dart';

/// A money row: leading visual, title, subtitle line, signed amount on the
/// right. The base of every transaction / debt / project-tx row so they all
/// share metrics, colours and the privacy toggle.
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
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    super.key,
  });

  final Widget leading;
  final String title;

  /// Free-form second line (text + small badges / icons).
  final Widget? subtitle;

  /// Optional third line under the subtitle (e.g. a row's short tags),
  /// same small text style.
  final Widget? footer;
  final num amount;
  final MoneyTone tone;

  /// Small text under the amount ("ติดคุณ", "หาร 3").
  final String? amountCaption;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
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
  }
}

/// Date group header for chronological lists: "วันนี้ · −฿540".
class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({required this.label, this.total, super.key});

  final String label;

  /// Optional net total of the group (signed).
  final num? total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          if (total != null)
            MoneyText(total!, tone: MoneyTone.signed, style: style),
        ],
      ),
    );
  }
}
