import 'package:flutter/material.dart';

import '../../atoms/skeleton_box.dart';
import '../../molecules/progress_row.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../icons/icon_code.dart';
import '../icons/icon_code_widget.dart';
import 'progress_tone.dart';

/// One progress item — a budget, a saving goal, a budget PERIOD (owner
/// 2026-10-13; the mockup `budget-v2.html`). A hairline-list row, not a
/// boxed card:
///
///   (icon)  title                                  [badge]
///           caption
///   ▓▓▓▓▓▓▓▓▒▒▒░░░░░░░░░░          used ▓ · expected ▒ (striped)
///   value label · over label                          122%
///
/// - leading tile: [iconCode] (+ [fallbackIcon] when it has none), or a
///   custom [leading]; none of them = no tile. [ProgressCard.compact] never
///   has one (a period row: title = "ต.ค. 2026").
/// - [badge]: a mini `StatusChip` (the BE's warning / danger) or any widget.
/// - bar: [value] (ratio, >1 = over) and [expected] (the not-yet-spent
///   ratio, a lighter striped segment); the bar clamps visually, the
///   percent text is [percentText] (the caller's string, NOT clamped —
///   "122%").
/// - [tone] picks the colour (neutral = the icon's tint) — never derived
///   from [value]. The percent text takes the tone colour unless neutral.
/// - [label]: the value line ("ใช้ ฿430 จาก ฿500 · คาด +฿35"); [overLabel]: an
///   optional second line in the danger colour ("เกินงบ ฿860"); [struckLabel]:
///   a muted struck-through tail ("฿8,000" — the limit before a period-only
///   change).
/// - [onTap]; [dimmed] fades it (archived).
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    required this.title,
    required this.value,
    this.caption,
    this.iconCode,
    this.fallbackIcon,
    this.leading,
    this.badge,
    this.expected,
    this.tone = ProgressTone.neutral,
    this.label,
    this.overLabel,
    this.struckLabel,
    this.percentText,
    this.onTap,
    this.dimmed = false,
    this.trailing,
    this.paceMarker,
    this.alignWithTitle = false,
    super.key,
  }) : compact = false,
       skeleton = false,
       skeletonIcon = true;

  /// The period-list variant: no icon tile, a thinner bar.
  const ProgressCard.compact({
    required this.title,
    required this.value,
    this.caption,
    this.badge,
    this.expected,
    this.tone = ProgressTone.neutral,
    this.label,
    this.overLabel,
    this.struckLabel,
    this.percentText,
    this.onTap,
    this.dimmed = false,
    this.trailing,
    this.paceMarker,
    this.alignWithTitle = false,
    super.key,
  }) : iconCode = null,
       fallbackIcon = null,
       leading = null,
       compact = true,
       skeleton = false,
       skeletonIcon = true;

  /// A loading placeholder with the same slots ([compact]: no icon tile;
  /// [withIcon] false: no tile either).
  const ProgressCard.skeleton({
    this.compact = false,
    bool withIcon = true,
    super.key,
  }) : title = '',
       value = 0,
       caption = null,
       iconCode = null,
       fallbackIcon = null,
       leading = null,
       badge = null,
       expected = null,
       tone = ProgressTone.neutral,
       label = null,
       overLabel = null,
       struckLabel = null,
       percentText = null,
       trailing = null,
       paceMarker = null,
       alignWithTitle = false,
       onTap = null,
       dimmed = false,
       skeleton = true,
       skeletonIcon = withIcon;

  final String title;
  final String? caption;
  final IconCode? iconCode;

  /// The glyph when [iconCode] is null (set one of the two to show a tile).
  final IconData? fallbackIcon;

  /// A custom leading widget (replaces the tile).
  final Widget? leading;
  final Widget? badge;
  final double value;
  final double? expected;
  final ProgressTone tone;
  final String? label;
  final String? overLabel;
  final String? struckLabel;
  final String? percentText;
  final VoidCallback? onTap;
  final bool dimmed;

  /// Far right of the name line, after the [badge] (a budget's "เหลือ ฿X").
  final Widget? trailing;

  /// Where on the bar a thin tick marks today's pace (0..1); null = none.
  final double? paceMarker;

  /// Bar and footer start under the title, not under the icon tile.
  final bool alignWithTitle;
  final bool compact;
  final bool skeleton;
  final bool skeletonIcon;

  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    if (skeleton) return _skeleton();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final tint = iconCode.tintFor(palette);
    final color = tone.resolve(context, entityTint: tint);
    final hasTile = leading != null || iconCode != null || fallbackIcon != null;
    final tinted = tone != ProgressTone.neutral && tone != ProgressTone.normal;
    final small = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasTile) ...[
          leading ??
              IconCodeWidget(
                iconCode: iconCode,
                size: _tile,
                displayMode: IconDisplayMode.compact,
                fallbackIcon: fallbackIcon ?? Icons.savings_outlined,
                fallbackColor: tint,
              ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: small,
                ),
            ],
          ),
        ),
        if (badge != null) ...[const SizedBox(width: AppSpacing.sm), badge!],
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );

    final hasFooter =
        label != null ||
        overLabel != null ||
        struckLabel != null ||
        percentText != null;
    final footer = !hasFooter
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label != null || struckLabel != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              if (label != null) TextSpan(text: label),
                              if (label != null && struckLabel != null)
                                const TextSpan(text: ' '),
                              if (struckLabel != null)
                                TextSpan(
                                  text: struckLabel,
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: small,
                        ),
                      if (overLabel != null)
                        Text(
                          overLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: small?.copyWith(
                            color: palette.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (percentText != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    percentText!,
                    key: const ValueKey('progressPercent'),
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tinted ? color : null,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          );

    final indent = alignWithTitle && hasTile ? _tile + AppSpacing.md : 0.0;
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.only(left: indent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ProgressRow(
                  value: value,
                  expected: expected,
                  color: color,
                  overColor: color,
                  height: compact ? 6 : 8,
                  marker: paceMarker,
                ),
                footer,
              ],
            ),
          ),
        ],
      ),
    );

    final row = Material(
      color: Colors.transparent,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }

  Widget _skeleton() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (!compact && skeletonIcon) ...const [
              SkeletonBox(width: _tile, height: _tile, shape: BoxShape.circle),
              SizedBox(width: AppSpacing.md),
            ],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 100, height: 10),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: compact ? 6 : 8, borderRadius: 8),
        const SizedBox(height: AppSpacing.sm),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBox(width: 120, height: 10),
            SkeletonBox(width: 28, height: 10),
          ],
        ),
      ],
    ),
  );
}
