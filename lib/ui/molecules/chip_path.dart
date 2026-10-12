import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_icon.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import '../tokens/icon_size.dart';

/// One step of a [ChipPath]: an entity's name with its OWN icon + colour.
class ChipPathSegment {
  const ChipPathSegment({required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;
}

/// A nested entity as a path of display chips — `[Food & Drinks] › [Food
/// Delivery]` (a category L1 › L2 › L3, owner 2026-10-12): every segment is its
/// own chip (chip 28) with its own icon + colour, joined by `›`. Too long for
/// the row → it scrolls sideways, parked on the LAST segment (the one that
/// matters); each chip also ellipsises its own label.
///
/// The value of a [DetailRow.pick] (`valueChip: ChipPath(...)`) wherever a
/// category is shown in a row. One segment = just that entity's chip.
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
