import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/color_token.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../domain/tag.dart';

/// A tag's one colour — its icon tint (tags never show a bg / border, so a
/// stored bg colour must not win here). No colour → the theme primary.
Color tagColor(IconCode? code, AppColors palette) =>
    (code?.iconColors.isNotEmpty ?? false)
    ? resolveColor(code!.iconColors.first, palette)
    : palette.primary;

/// The full tag look — `[icon] name [×count]` in a pill: border, icon and
/// text all in the tag colour on a light tint of it. Used wherever a tag is
/// shown on its own (tags page preview, tx detail, tag pickers).
///
/// [selected] turns it into a picker chip: `null` = plain display, `true` =
/// the full look, `false` = a neutral outline (icon keeps its colour).
/// [showUsage] adds the `×n` usage count (tags page only).
class TagChip extends StatelessWidget {
  const TagChip({
    required this.tag,
    this.selected,
    this.showUsage = false,
    this.onTap,
    this.onLongPress,
    this.onIconTap,
    super.key,
  });

  final Tag tag;
  final bool? selected;
  final bool showUsage;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final color = tagColor(tag.iconCode, palette);
    final on = selected ?? true;
    final fg = on ? color : scheme.onSurfaceVariant;
    final usageLabel = showUsage ? l.tagsUsageCount(tag.usageCount) : '';
    final iconData = IconRegistry.get(
      tag.iconCode?.icon,
      fallback: AppIcons.tag,
    );

    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onIconTap != null)
          InkResponse(
            onTap: onIconTap,
            radius: 18,
            child: Icon(iconData, size: 16, color: color),
          )
        else
          Icon(iconData, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            tag.name.isEmpty ? l.tagFormNameLabel : tag.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (usageLabel.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            usageLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ],
    );

    return Material(
      color: on ? color.withValues(alpha: 0.12) : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: on ? color : scheme.outlineVariant,
          width: on ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 2,
            vertical: AppSpacing.xs,
          ),
          child: body,
        ),
      ),
    );
  }
}

/// The short tag form — `#name #name …` in each tag's colour, one line,
/// ellipsised. For dense rows (transaction list, pending) where a full
/// [TagChip] doesn't fit.
class TagShortList extends StatelessWidget {
  const TagShortList({required this.tags, this.style, super.key});

  final List<Tag> tags;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return Text.rich(
      TextSpan(
        children: [
          for (final (i, t) in tags.indexed)
            TextSpan(
              text: '${i > 0 ? '  ' : ''}#${t.name}',
              style: TextStyle(
                color: tagColor(t.iconCode, palette),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
