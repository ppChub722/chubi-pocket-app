import 'package:flutter/material.dart';

import '../tokens/app/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';

/// A small stat card (the budget mockup's `.tile`): a muted [caption], a big
/// [value] (a string, or any widget — a `MoneyText`), an optional muted
/// [subCaption], with a soft tint + border for [Tone.warning] / [Tone.danger]
/// (any other tone = a plain tile). Put them in a [StatGrid].
class StatTile extends StatelessWidget {
  const StatTile({
    required this.caption,
    this.value,
    this.valueWidget,
    this.subCaption,
    this.tone = Tone.neutral,
    this.onTap,
    super.key,
  }) : assert(
         value != null || valueWidget != null,
         'give a value or a valueWidget',
       );

  final String caption;

  /// The figure as text ("19 ต.ค.", "฿165").
  final String? value;

  /// The figure as a widget — wins over [value].
  final Widget? valueWidget;
  final String? subCaption;
  final Tone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final tinted = tone == Tone.warning || tone == Tone.danger;
    final accent = tone == Tone.warning
        ? palette.warning
        : tone == Tone.danger
        ? palette.error
        : null;
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final radius = BorderRadius.circular(AppRadius.md);
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(caption, style: muted, maxLines: 1),
          const SizedBox(height: AppSpacing.xxs),
          valueWidget ??
              Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
          if (subCaption != null) Text(subCaption!, style: muted, maxLines: 2),
        ],
      ),
    );
    return Material(
      color: tinted ? accent!.withValues(alpha: 0.07) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: tinted
              ? accent!.withValues(alpha: 0.45)
              : scheme.outlineVariant,
        ),
      ),
      child: onTap == null
          ? body
          : InkWell(borderRadius: radius, onTap: onTap, child: body),
    );
  }
}

/// A grid of [StatTile]s, [columns] wide (default 2), each row as tall as its
/// tallest tile. A short last row leaves its empty cells empty.
class StatGrid extends StatelessWidget {
  const StatGrid({
    required this.children,
    this.columns = 2,
    this.spacing = AppSpacing.sm,
    super.key,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: spacing),
                Expanded(
                  child: i + c < children.length
                      ? children[i + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          rows[i],
        ],
      ],
    );
  }
}
