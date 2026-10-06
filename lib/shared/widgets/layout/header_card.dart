import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// The bordered card at the top of every detail page: leading visual
/// (icon / avatar) + title + optional subtitle lines, accent-coloured
/// border, optional trailing (status pill) and [footer] (progress, member
/// strip, …).
///
/// [title] is a widget so a page can swap a read-only `Text` for an
/// `InlineTitleField` in edit mode without the card changing height.
class HeaderCard extends StatelessWidget {
  const HeaderCard({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.footer,
    this.accent,
    this.onTap,
    super.key,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? footer;

  /// Border colour; defaults to the primary colour.
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = accent ?? scheme.primary;
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.titleMedium,
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle.merge(
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: border, width: 1.5),
      ),
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}
