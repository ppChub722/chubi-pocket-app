import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/list_break.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/typography.dart';

class SectionHeader extends StatelessWidget implements ListBreak {
  const SectionHeader({
    required this.title,
    this.leading,
    this.count,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.totalLabel,
    this.total,
    this.totalColor,
    // No end inset: the trailing ends flush with the cards below it (the
    // list's gutter), owner 2026-10-21.
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      0,
      AppSpacing.xs,
    ),
    super.key,
  });

  final String title;

  final Widget? leading;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// An icon action at the end instead (the wallet groups' ⇅).
  final Widget? trailing;

  /// A small [totalLabel] then the [total] text in [totalColor], at the end
  /// (a debts section's "รวม ฿1,200"); used when there is no [trailing].
  final String? totalLabel;
  final String? total;
  final Color? totalColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = this.total;
    final end =
        trailing ??
        (total == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (totalLabel != null) ...[
                    AppText(totalLabel!, role: AppTextRole.caption),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    total,
                    style: textTheme.labelLarge?.copyWith(color: totalColor),
                  ),
                ],
              ));
    final hasEnd = (actionLabel != null && onAction != null) || end != null;
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, box) {
          // The end keeps its own width when there's room; on a narrow screen
          // it's capped so the title keeps [_minTitle] (it ellipsizes first,
          // then a long trailing text wraps) — never an overflow.
          final endMax = (box.maxWidth - _minTitle).clamp(0.0, double.infinity);
          return Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              // One Expanded holds the title + count, so the trailing always
              // sits at the end. (A loose Flexible title + a Spacer left the
              // title's unused share AFTER the trailing, ending it short of
              // the cards.)
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '| $count',
                        style: textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasEnd) ...[
                const SizedBox(width: AppSpacing.sm),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: endMax),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (actionLabel != null && onAction != null)
                        AppButton(
                          label: actionLabel!,
                          onPressed: onAction,
                          variant: AppButtonVariant.text,
                          trailingIcon: AppIcons.chevronRight,
                        ),
                      if (end != null) Flexible(child: end),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// What the title (+ count) always keeps on a narrow screen.
  static const double _minTitle = 120;
}
