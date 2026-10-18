import 'package:flutter/material.dart';

import '../atoms/app_card.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../atoms/dashed_rect_border.dart';

class PickCard extends StatelessWidget {
  const PickCard({
    required this.label,
    required this.leading,
    required this.onTap,
    this.value,
    this.placeholder,
    this.subtitle,
    this.accent,
    this.errorText,
    this.watermark,
    this.dense = false,
    this.reserveSubtitle = false,
    this.trailing,
    this.editable = false,
    this.onLongPress,
    super.key,
  });

  final bool editable;

  final VoidCallback? onLongPress;

  final bool reserveSubtitle;

  final Widget? trailing;

  final IconData? watermark;

  final String label;
  final Widget leading;
  final String? value;
  final String? placeholder;

  final Widget? subtitle;

  final Color? accent;

  final VoidCallback? onTap;
  final String? errorText;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final empty = value == null;
    final tint = empty ? null : accent;
    final hasError = errorText != null;
    final Widget card = AppCard(
      style: empty
          ? AppCardStyle.flat
          : tint == null
          ? AppCardStyle.plain
          : AppCardStyle.tinted,
      color: tint,
      glyph: empty ? null : watermark,
      glyphSize: 72,
      borderColor: empty
          ? null
          : hasError
          ? scheme.error
          : editable
          ? Colors.transparent
          : tint == null
          ? scheme.outlineVariant
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Opacity(opacity: empty ? 0.6 : 1, child: leading),
              SizedBox(width: dense ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasError && !reserveSubtitle ? errorText! : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: hasError && !reserveSubtitle
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value ?? placeholder ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: StrutStyle.fromTextStyle(
                        textTheme.titleMedium!,
                        forceStrutHeight: true,
                      ),
                      style: empty
                          ? textTheme.titleSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )
                          : textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                    ),
                    if (reserveSubtitle || (!empty && subtitle != null))
                      if (hasError)
                        Text(
                          errorText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        )
                      else if (!empty && subtitle != null)
                        DefaultTextStyle.merge(
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: subtitle!,
                        )
                      else
                        Text(' ', style: textTheme.bodySmall),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );

    if (empty) {
      return DashedRectBorder(
        color: hasError ? scheme.error : scheme.outline,
        borderRadius: const Radius.circular(AppRadius.lg),
        child: card,
      );
    }
    if (editable && !hasError) {
      final line = tint ?? scheme.outline;
      // passthrough: under a fixed height (a flow row) the card fills it like
      // the lines drawn over it, instead of hugging its content.
      return Stack(
        fit: StackFit.passthrough,
        children: [
          card,
          Positioned.fill(
            child: IgnorePointer(
              child: DashedRectBorder(
                color: line,
                strokeWidth: 1,
                dashLength: 4,
                gapLength: 3,
                borderRadius: const Radius.circular(AppRadius.lg),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg - 3),
                    border: Border.all(color: line),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return card;
  }
}

class PickCardEmptyIcon extends StatelessWidget {
  const PickCardEmptyIcon(this.icon, {this.size = 40, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.55, color: scheme.onSurfaceVariant),
    );
  }
}
