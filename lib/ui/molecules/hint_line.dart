import 'package:flutter/material.dart';

import '../atoms/app_icon.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

/// A muted line under a field: what will happen, or a soft warning. A link
/// beside it is an AppButton of its own.
class HintLine extends StatelessWidget {
  const HintLine({required this.text, this.icon, super.key});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            text,
            style: style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
