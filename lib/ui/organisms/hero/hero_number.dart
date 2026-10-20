import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';

enum HeroNumberLayout { stacked, inline }

class HeroNumber extends StatelessWidget {
  const HeroNumber({
    required this.value,
    this.label,
    this.color,
    this.target,
    this.onLabelTap,
    this.layout = HeroNumberLayout.stacked,
    this.small = false,
    super.key,
  });

  final Widget value;
  final String? label;
  final Color? color;
  final String? target;

  final VoidCallback? onLabelTap;
  final HeroNumberLayout layout;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hero = HeroColors.maybeOf(context);
    final muted = hero?.muted ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final inline = layout == HeroNumberLayout.inline;
    final big = (small ? text.titleLarge : text.headlineMedium)?.copyWith(
      fontWeight: inline ? FontWeight.w800 : FontWeight.w700,
      color: color ?? hero?.accent,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget? labelText;
    if (label != null) {
      labelText = Text(
        label!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: inline
            ? text.titleMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w700,
              )
            : text.labelLarge?.copyWith(color: muted),
      );
      if (onLabelTap != null) {
        labelText = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onLabelTap,
          child: labelText,
        );
      }
    }
    final number = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (inline && labelText != null) ...[
          labelText,
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: DefaultTextStyle.merge(style: big, child: value),
        ),
        if (target != null) ...[
          SizedBox(width: inline ? AppSpacing.sm : AppSpacing.xs),
          Flexible(
            child: Text(
              target!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (inline ? text.bodyMedium : text.bodySmall)?.copyWith(
                color: muted,
              ),
            ),
          ),
        ],
      ],
    );
    if (inline || labelText == null) return number;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [labelText, number],
    );
  }
}
