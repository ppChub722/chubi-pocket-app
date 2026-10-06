import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';

/// Section title with an optional count and a trailing "ดูทั้งหมด ›" style
/// action — dashboard cards, member strips, grouped lists.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.count,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
    super.key,
  });

  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '· $count',
              style: textTheme.titleMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const Spacer(),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const Icon(AppIcons.chevronRight, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
