import 'package:flutter/material.dart';

import '../atoms/corner_badge.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/avatar_metrics.dart';
import '../tokens/hero_colors.dart';

/// How tall and how spaced an [AppRow] is. A list item ([AppListRow]) and a
/// field of a detail page ([AppDetailRow]) share the shell, not the rhythm.
enum AppRowDensity {
  /// 8 / 8 padding; the leading is as big as the caller makes it.
  list(
    vertical: AppSpacing.sm,
    valueGap: AppSpacing.sm,
    subtitleGap: AppSpacing.xxs,
    leadingSize: AvatarMetrics.sizeMedium,
    iconSize: null,
    inkOnPressOnly: false,
    ownMaterial: true,
  ),

  /// 12 / 12 padding, a 22 px muted leading icon, ink only while pressed.
  detail(
    vertical: AppSpacing.md,
    valueGap: AppSpacing.md,
    subtitleGap: AppSpacing.xs,
    leadingSize: 22,
    iconSize: 22,
    inkOnPressOnly: true,
    ownMaterial: false,
  );

  const AppRowDensity({
    required this.vertical,
    required this.valueGap,
    required this.subtitleGap,
    required this.leadingSize,
    required this.iconSize,
    required this.inkOnPressOnly,
    required this.ownMaterial,
  });

  final double vertical;

  /// Between the title column and the trailing value.
  final double valueGap;

  /// Between the title and the subtitle.
  final double subtitleGap;

  /// The leading slot's size for a [RowBadge] and for
  /// [AppRow.reserveLeading].
  final double leadingSize;

  /// Icons in the leading slot get this size and the muted colour; null =
  /// the leading styles itself.
  final double? iconSize;

  /// No hover / focus wash, only the press ink (a detail field).
  final bool inkOnPressOnly;

  /// Always its own [Material] (a list row resets the text style to the
  /// theme's body); else only when it has a fill.
  final bool ownMaterial;
}

/// A corner badge on [AppRow.leading]: an icon or a brand logo image.
@immutable
class RowBadge {
  const RowBadge({this.icon, this.image, this.color, this.tooltip})
    : assert(icon != null || image != null, 'an icon or an image');

  /// A logo badge (the app that gave a picture).
  const RowBadge.logo(Widget this.image, {this.color, this.tooltip})
    : icon = null;

  final IconData? icon;

  /// A brand logo, clipped to the disc.
  final Widget? image;

  /// The disc behind the glyph; null = primary (icon) or surface (image).
  final Color? color;
  final String? tooltip;
}

/// The corner radius of the card cell a row sits in ([SectionCard] sets it),
/// so a filled row (tinted, highlighted) keeps the card's round corners.
class AppRowShape extends InheritedWidget {
  const AppRowShape({
    required this.borderRadius,
    required super.child,
    super.key,
  });

  final BorderRadius borderRadius;

  static BorderRadius? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppRowShape>()?.borderRadius;

  @override
  bool updateShouldNotify(AppRowShape old) => borderRadius != old.borderRadius;
}

/// The one row shell under [AppListRow] and [AppDetailRow]: [selector] ·
/// leading (+ [badge]) · title / subtitle · trailing (+ icon) · actions ·
/// chevron, then [footer]. It owns padding, fill (highlighted / tinted from
/// [accent]), ink, dim and disabled; the two rows own their content.
class AppRow extends StatelessWidget {
  const AppRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.badge,
    this.leadingSize,
    this.reserveLeading = false,
    this.selector,
    this.trailing,
    this.trailingMaxFraction,
    this.trailingIcon,
    this.trailingIconColor,
    this.chevron = false,
    this.actions = const [],
    this.footer,
    this.accent,
    this.tinted = false,
    this.highlighted = false,
    this.dimmed = false,
    this.disabled = false,
    this.density = AppRowDensity.list,
    this.indent = 0,
    this.horizontalInset = AppSpacing.lg,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget title;

  /// Under [title], [AppRowDensity.subtitleGap] below it.
  final Widget? subtitle;
  final Widget? leading;

  /// Shown on [leading]'s corner at any size.
  final RowBadge? badge;

  /// A fixed square slot for the leading (content centred, never scaled):
  /// rows with an icon, a logo or an avatar line up, badge or not. Also sizes
  /// the [badge] disc and the [reserveLeading] room; null = no slot (the
  /// leading's own size) and the density's size for the badge.
  final double? leadingSize;

  /// No [leading]: keep its room so the titles of a group line up.
  final bool reserveLeading;

  /// Before [leading] (a select check), 4 px from it.
  final Widget? selector;
  final Widget? trailing;

  /// The trailing value's widest share of the row (0.5 = half); null = as
  /// wide as it is.
  final double? trailingMaxFraction;

  /// A 16 px icon after the value (🔒, 🔗).
  final IconData? trailingIcon;

  /// Null = muted.
  final Color? trailingIconColor;
  final bool chevron;

  /// At the far right; taps here never reach [onTap].
  final List<Widget> actions;

  /// Under the title and value, from the title's left edge to the right.
  final Widget? footer;

  /// The row's own colour: pieces inside read it through [HeroColors]; with
  /// [tinted] it also fills the row (contrast-checked accent, soft wash).
  final Color? accent;
  final bool tinted;

  /// The primary 8 % fill (selected, the item just opened).
  final bool highlighted;

  /// 55 %, still tappable (an archived or paid item).
  final bool dimmed;

  /// 38 %, no taps, no ink (coming soon, not allowed).
  final bool disabled;
  final AppRowDensity density;
  final double indent;
  final double horizontalInset;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static final WidgetStateProperty<Color?> _pressOnly =
      WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.pressed) ? null : Colors.transparent,
      );

  /// The colours a row with [accent] uses (null without one).
  static HeroColors? colorsFor(BuildContext context, Color? accent) =>
      accent == null ? null : HeroColors.from(Theme.of(context), accent);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final d = density;
    final hero = colorsFor(context, accent);
    final fill = highlighted
        ? scheme.primary.withValues(alpha: 0.08)
        : tinted && hero != null
        ? hero.soft
        : null;
    final muted = scheme.onSurfaceVariant;
    final square = leadingSize ?? d.leadingSize;

    Widget? lead = leading;
    if (lead != null && d.iconSize != null) {
      lead = IconTheme.merge(
        data: IconThemeData(
          color: tinted && hero != null ? hero.accent : muted,
          size: d.iconSize,
        ),
        child: lead,
      );
    }
    // A set leadingSize is a fixed slot: an icon, a logo and an avatar (with
    // or without a badge) all sit in the same square, so rows line up and
    // the badge always lands on the same corner. The content keeps its own
    // size (centred); it is never scaled.
    if (lead != null && leadingSize != null) {
      lead = SizedBox.square(
        dimension: leadingSize,
        child: Center(child: lead),
      );
    }
    final badge = this.badge;
    if (lead != null && badge != null) {
      lead = CornerBadge(
        size: square,
        icon: badge.icon,
        glyph: badge.image,
        color: badge.color,
        tooltip: badge.tooltip,
        essential: true,
        // The leading keeps its own size and place; the badge only overlays
        // its corner (owner 2026-10-28).
        hug: true,
        child: lead,
      );
    }

    final subtitle = this.subtitle;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(top: d.subtitleGap),
            child: subtitle,
          ),
      ],
    );

    Widget line(double? maxWidth) {
      final trailing = this.trailing;
      return Row(
        children: [
          Expanded(child: text),
          if (trailing != null) ...[
            SizedBox(width: d.valueGap),
            if (maxWidth == null)
              trailing
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: trailing,
              ),
          ],
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(trailingIcon, size: 16, color: trailingIconColor ?? muted),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, a) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    a,
                  ],
                ],
              ),
            ),
          ],
          if (chevron) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.chevronRight, color: muted),
          ],
        ],
      );
    }

    Widget content(double? maxWidth) => Row(
      children: [
        if (selector case final s?) ...[
          s,
          const SizedBox(width: AppSpacing.xs),
        ],
        if (lead != null) ...[
          lead,
          const SizedBox(width: AppSpacing.md),
        ] else if (reserveLeading) ...[
          SizedBox(width: square + AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              line(maxWidth),
              if (footer case final f?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: f,
                ),
            ],
          ),
        ),
      ],
    );

    final fraction = trailingMaxFraction;
    Widget row = Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset + indent,
        d.vertical,
        horizontalInset,
        d.vertical,
      ),
      child: fraction == null || trailing == null
          ? content(null)
          : LayoutBuilder(
              builder: (context, box) => content(box.maxWidth * fraction),
            ),
    );

    final radius = AppRowShape.of(context);
    final tappable = !disabled && (onTap != null || onLongPress != null);
    if (tappable) {
      row = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        overlayColor: d.inkOnPressOnly ? _pressOnly : null,
        child: row,
      );
    }
    if (d.ownMaterial || fill != null) {
      row = Material(
        color: fill ?? Colors.transparent,
        borderRadius: radius,
        textStyle: d.ownMaterial ? null : DefaultTextStyle.of(context).style,
        child: row,
      );
    }
    if (hero != null) row = HeroColorScope(colors: hero, child: row);
    if (disabled) {
      return IgnorePointer(child: Opacity(opacity: 0.38, child: row));
    }
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}
