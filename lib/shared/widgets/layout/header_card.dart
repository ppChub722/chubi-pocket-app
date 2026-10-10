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
///
/// [topRow] (owner 2026-10-11) adds the hero's top row ([HeroTopRow], every
/// control [HeroSpacing.controlHeight] high): these chips on the left,
/// [topActions] then ✏️ on the right — ✏️ moves up there from the title
/// row. The row keeps its height without ✏️ (edit mode), so nothing below
/// moves:
///
///   [type][status]                  [action] ✏️
///   (icon)  title
///           subtitle
///   footer
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
    this.topRow,
    this.topActions = const [],
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

  /// Non-null → the top row: these chips (type / status pills,
  /// [PillSize.normal]) on the left; ✏️ moves into it.
  final List<Widget>? topRow;

  /// The top row's actions, left of ✏️ ("ปรับยอด"); needs [topRow].
  final List<Widget> topActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = accent ?? scheme.primary;
    final top = topRow;
    final edit = onEdit == null
        ? null
        : AppIconButton(
            icon: AppIcons.edit,
            size: HeroSpacing.controlHeight,
            tooltip: AppLocalizations.of(context)!.commonEdit,
            onPressed: onEdit,
          );
    // The kit's hero spacing ([HeroContent]): 16 inside, 12 between rows,
    // 8 between the title column and the ✏️ / trailing controls.
    final body = HeroContent(
      rows: [
        if (top != null)
          HeroTopRow(leading: top, trailing: [...topActions, ?edit]),
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
            if (edit != null && top == null) ...[
              const SizedBox(width: HeroSpacing.itemGap),
              edit,
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
