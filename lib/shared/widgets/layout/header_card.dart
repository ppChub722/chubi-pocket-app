import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../buttons/app_icon_button.dart';
import 'hero_shell.dart';

/// The bordered card at the top of every detail page: leading visual
/// (icon / avatar) + title + optional subtitle lines, accent-coloured
/// border, optional trailing (status pill) and [footer] (progress, member
/// strip, …).
///
/// [onEdit] adds a small ✏️ chip at the right of the title row — the page's way
/// into edit mode now that the top bar carries no page actions (owner rule
/// 2026-10-09; long-press still works too). Pass null while editing.
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
    this.onEdit,
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

  /// Shows the ✏️ chip (enter edit mode); null hides it.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = accent ?? scheme.primary;
    // The kit's hero spacing ([HeroContent]): 16 inside, 12 to the footer,
    // 8 between the title column and the ✏️ / trailing controls.
    final body = HeroContent(
      rows: [
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: HeroSpacing.itemGap),
              AppIconButton(
                icon: AppIcons.edit,
                size: HeroSpacing.controlHeight,
                tooltip: AppLocalizations.of(context)!.commonEdit,
                onPressed: onEdit,
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: HeroSpacing.itemGap),
              trailing!,
            ],
          ],
        ),
        footer,
      ],
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
