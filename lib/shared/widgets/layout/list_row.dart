import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../inputs/select_check.dart';

/// One row of a library list — categories, tags, contacts (owner
/// 2026-10-10, option A), on hairline-separated rows:
///
///   [☐] (icon)  name                        trailing info
///               one-line description
///
/// [leading] is the icon circle (IconDisplay / UserAvatar, 40); [subtitle]
/// one line; [trailing] the row's info (×usage, 🔗, ▾/▴, pills). [indent]
/// shifts it right (a tree's levels); [dimmed] fades it (archived);
/// [checked] non-null shows a [SelectCheck] first (batch-edit mode) and
/// tints the row when true; [body] replaces the title + subtitle (an
/// inline name field in batch edit). No ListTile.
class ListRow extends StatelessWidget {
  const ListRow({
    this.title,
    this.body,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.indent = 0,
    this.dimmed = false,
    this.checked,
    this.onCheck,
    super.key,
  }) : assert(title != null || body != null);

  final String? title;
  final Widget? body;
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double indent;
  final bool dimmed;

  /// Batch-edit mode: the row's check (null = not selecting).
  final bool? checked;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selecting = checked != null;
    final row = Material(
      color: (checked ?? false)
          ? scheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg + indent,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              if (selecting) ...[
                SelectCheck(value: checked, onTap: onCheck ?? onTap),
                const SizedBox(width: AppSpacing.md),
              ],
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child:
                    body ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}
