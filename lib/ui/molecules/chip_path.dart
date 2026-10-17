import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_icon.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import '../tokens/icon_size.dart';

class ChipPathSegment {
  const ChipPathSegment({required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;
}

class ChipPath extends StatelessWidget {
  const ChipPath({required this.segments, super.key});

  final List<ChipPathSegment> segments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, s) in segments.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                child: AppIcon(
                  AppIcons.chevronRight,
                  size: AppIconSize.sm,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            AppChip(
              label: s.label,
              icon: s.icon,
              color: s.color,
              size: ChipSize.chip,
              maxWidth: 160,
            ),
          ],
        ],
      ),
    );
  }
}
