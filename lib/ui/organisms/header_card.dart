import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';
import '../molecules/hero_style.dart';
import '../molecules/card_action_button.dart';
import '../tokens/app/app_icons.dart';
import '../molecules/hero_shell.dart';

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
///           description (2 lines, muted)
///           subtitle (chips like "Linked")
///   footer
///
/// A [topRow] with no chips (and no [topActions]) collapses: no empty band —
/// the icon + title block moves to the top and ✏️ sits at the right of the
/// title row. With chips nothing changes.
class HeaderCard extends StatelessWidget {
  const HeaderCard({
    required this.leading,
    required this.title,
    this.description,
    this.subtitle,
    this.trailing,
    this.footer,
    this.accent,
    this.glyph,
    this.heroStyle,
    this.onTap,
    this.onEdit,
    this.topRow,
    this.topActions = const [],
    super.key,
  });

  final Widget leading;
  final Widget title;

  /// The description under the name (muted, 2 lines; edited in place in edit
  /// mode) — a `HeroDescription`. Hidden by passing null or an empty one.
  final Widget? description;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? footer;

  /// Border colour; defaults to the primary colour.
  final Color? accent;

  /// The faint watermark icon in the corner (owner 2026-10-12: every entity's
  /// hero is washed in its colour with a watermark, like the wallet card).
  final IconData? glyph;

  /// The hero's look as one object (also handed to its [CompactHeroBar]); null
  /// = tinted in [accent] with [glyph].
  final HeroStyle? heroStyle;
  final VoidCallback? onTap;

  /// Shows the ✏️ chip (enter edit mode); null hides it.
  final VoidCallback? onEdit;

  /// Non-null → the top row: these chips (type / status pills,
  /// [ChipSize.control]) on the left; ✏️ moves into it.
  final List<Widget>? topRow;

  /// The top row's actions, left of ✏️ ("ปรับยอด"); needs [topRow].
  final List<Widget> topActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = accent ?? scheme.primary;
    // No chips and no actions → the top row collapses (owner 2026-10-11): the
    // icon + title block sits at the top and ✏️ goes level with the title.
    final top = (topRow?.isNotEmpty ?? false) || topActions.isNotEmpty
        ? (topRow ?? const <Widget>[])
        : null;
    final edit = onEdit == null
        ? null
        : CardActionButton(
            icon: AppIcons.edit,
            tooltip: UiConfig.stringsOf(context).edit,
            onTap: onEdit,
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
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    description!,
                  ],
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
    return HeroSurface(
      style: heroStyle ?? HeroStyle.tinted(color: border, glyph: glyph),
      onTap: onTap,
      child: body,
    );
  }
}
