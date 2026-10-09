import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// A card washed in one colour: a soft gradient from the top-left, a border
/// in the same tint and (optionally) a big faded [glyph] in the corner —
/// the look of the wallet cards and the เพิ่มเติม hub, shared so every
/// "this is a thing of colour X" card reads the same (owner 2026-10-09).
///
/// ```dart
/// TintedCard(
///   tint: moduleColors.planning,
///   glyph: AppIcons.budget,
///   onTap: () => context.push('/budgets'),
///   child: Padding(padding: …, child: …),
/// )
/// ```
class TintedCard extends StatelessWidget {
  const TintedCard({
    required this.tint,
    required this.child,
    this.glyph,
    this.glyphSize = 88,
    this.onTap,
    this.margin,
    super.key,
  });

  final Color tint;
  final Widget child;

  /// Corner watermark; null = none.
  final IconData? glyph;
  final double glyphSize;
  final VoidCallback? onTap;

  /// Card margin; null = the theme default.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: tint.withValues(alpha: 0.25)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint.withValues(alpha: 0.16),
              tint.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (glyph != null)
                Positioned(
                  right: -glyphSize * 0.16,
                  bottom: -glyphSize * 0.2,
                  child: Icon(
                    glyph,
                    size: glyphSize,
                    color: tint.withValues(alpha: 0.10),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// The solid rounded-square icon that heads a [TintedCard] (เพิ่มเติม hub,
/// dashboard tiles).
class TintedIconBadge extends StatelessWidget {
  const TintedIconBadge({
    required this.icon,
    required this.tint,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Module / accent colours are saturated — white reads on all of them.
    const onTint = Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(
          size >= 40 ? AppRadius.md : AppRadius.sm,
        ),
      ),
      child: Icon(icon, size: size * 0.55, color: onTint),
    );
  }

  /// Gap under a badge before the card's title.
  static const gap = SizedBox(height: AppSpacing.sm);
}
