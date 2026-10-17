import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';
import '../molecules/hero_style.dart';
import '../molecules/card_action_button.dart';
import '../tokens/app/app_icons.dart';
import '../molecules/hero_shell.dart';

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

  final Widget? description;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? footer;

  final Color? accent;

  final IconData? glyph;

  final HeroStyle? heroStyle;
  final VoidCallback? onTap;

  final VoidCallback? onEdit;

  final List<Widget>? topRow;

  final List<Widget> topActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = accent ?? scheme.primary;
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
