import 'package:flutter/material.dart';

import '../atoms/app_icon.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

class HintLine extends StatelessWidget {
  const HintLine({
    required this.text,
    this.icon,
    this.linkLabel,
    this.onTap,
    super.key,
  });

  final String text;
  final IconData? icon;
  final String? linkLabel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final link = linkLabel;
    final line = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                if (link != null) ...[
                  TextSpan(
                    text: link,
                    style: style?.copyWith(
                      color: onTap == null ? null : scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onTap != null)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: AppIcon(
                        AppIcons.chevronRight,
                        size: AppIconSize.sm,
                        color: scheme.primary,
                      ),
                    ),
                  const TextSpan(text: ' '),
                ],
                TextSpan(text: text),
              ],
            ),
            style: style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    if (onTap == null) return line;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: line,
      ),
    );
  }
}
