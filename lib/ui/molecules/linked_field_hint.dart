import 'package:flutter/material.dart';

import '../atoms/app_icon.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

class LinkedFieldHint extends StatelessWidget {
  const LinkedFieldHint({required this.text, this.padding, super.key});

  final String text;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(
          AppIcons.link,
          size: AppIconSize.sm,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
    return padding == null ? line : Padding(padding: padding!, child: line);
  }
}
