import 'package:flutter/material.dart';

import '../../atoms/skeleton_box.dart';
import '../../molecules/progress_row.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../icons/icon_code.dart';
import '../icons/icon_code_widget.dart';
import 'progress_tone.dart';

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
    this.paceBubble,
    this.alignWithTitle = false,
    super.key,
  }) : compact = false,
       skeleton = false,
       skeletonIcon = true;

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
    this.paceBubble,
    this.alignWithTitle = false,
    super.key,
  }) : iconCode = null,
       fallbackIcon = null,
       leading = null,
       compact = true,
       skeleton = false,
       skeletonIcon = true;

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
       paceBubble = null,
       alignWithTitle = false,
       onTap = null,
       dimmed = false,
       skeleton = true,
       skeletonIcon = withIcon;

  final String title;
  final String? caption;
  final IconCode? iconCode;

  final IconData? fallbackIcon;

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

  final Widget? trailing;

  final double? paceMarker;

  /// Shown over the [paceMarker] all the time ("plan to date ฿1,300").
  final String? paceBubble;

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

    final header = LayoutBuilder(
      builder: (context, box) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasTile) ...[
            leading ??
                IconCodeWidget(
                  iconCode: iconCode,
                  size: _tile,
                  displayMode: IconDisplayMode.compact,
                  fallbackIcon: fallbackIcon ?? AppIcons.budget,
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
          if (badge != null) ...[
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.35),
              child: badge!,
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.45),
              child: trailing!,
            ),
          ],
        ],
      ),
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
                  markerBubble: paceBubble,
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

class ProgressRemainder extends StatelessWidget {
  const ProgressRemainder({
    required this.label,
    required this.amount,
    this.over = false,
    super.key,
  });

  final String label;

  final String amount;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final small = Theme.of(context).textTheme.bodySmall;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: small?.copyWith(
              color: over ? palette.error : scheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: amount,
            style: small?.copyWith(
              fontWeight: FontWeight.w700,
              color: over ? palette.error : scheme.onSurface,
            ),
          ),
        ],
      ),
      maxLines: 1,
    );
  }
}

class ProgressBadges extends StatelessWidget {
  const ProgressBadges({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, c) in children.indexed) ...[
        if (i > 0) const SizedBox(width: AppSpacing.xs),
        Flexible(child: c),
      ],
    ],
  );
}
