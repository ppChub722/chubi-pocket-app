import 'package:flutter/material.dart';

import '../tokens/app/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';

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

  final String? value;

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
