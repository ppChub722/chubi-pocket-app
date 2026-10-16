import 'package:flutter/material.dart';

import '../atoms/list_break.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';

/// Section title with an optional count and a trailing "ดูทั้งหมด ›" style
/// action — dashboard cards, member strips, grouped lists.
class SectionHeader extends StatelessWidget implements ListBreak {
  const SectionHeader({
    required this.title,
    this.leading,
    this.count,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      PpForgeSpacing.lg,
      PpForgeSpacing.md,
      PpForgeSpacing.sm,
      PpForgeSpacing.xs,
    ),
    super.key,
  });

  final String title;

  /// An icon (or any widget) before the title — a group's mark.
  final Widget? leading;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// An icon action at the end instead (the wallet groups' ⇅).
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: PpForgeSpacing.sm),
          ],
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
            const SizedBox(width: PpForgeSpacing.xs),
            Text(
              '· $count',
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: PpForgeSpacing.sm,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const Icon(PpForgeIcons.chevronRight, size: 18),
                ],
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}
