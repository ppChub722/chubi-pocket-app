import 'package:flutter/material.dart';

import '../../atoms/app_icon.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import '../../tokens/icon_size.dart';

@immutable
class HeroFact {
  const HeroFact(
    this.label,
    this.value, {
    this.color,
    this.dot,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  final String label;
  final String value;

  /// Paints the value (a status: over, warning); null = the card's text.
  final Color? color;

  /// A dot before the label, tying the row to a bar or ring part's color.
  final Color? dot;

  /// An icon before the label, in place of [dot]. Its color is [iconColor],
  /// then [dot] (a split-bar legend), then the card's accent.
  final IconData? icon;
  final Color? iconColor;

  /// Makes the row a link: a › follows the value.
  final VoidCallback? onTap;
}

/// Label / value rows split by dashed lines, beside a hero's ring (see
/// HeroRingRow).
class HeroFactList extends StatelessWidget {
  const HeroFactList({required this.facts, super.key});

  final List<HeroFact> facts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.bodyMedium;
    final hero = HeroColors.maybeOf(context);
    final muted = hero?.muted ?? scheme.onSurfaceVariant;
    final line = hero?.line ?? scheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, f) in facts.indexed) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: CustomPaint(
                size: const Size.fromHeight(1),
                painter: _DashPainter(line),
              ),
            ),
          _link(
            f.onTap,
            Row(
              children: [
                if (f.icon != null) ...[
                  AppIcon(
                    f.icon!,
                    size: AppIconSize.sm,
                    color:
                        f.iconColor ?? f.dot ?? hero?.accent ?? scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm - 2),
                ] else if (f.dot != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: f.dot,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                  const SizedBox(width: AppSpacing.sm - 2),
                ],
                Expanded(
                  child: Text(
                    f.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text?.copyWith(color: muted),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  f.value,
                  maxLines: 1,
                  style: text?.copyWith(
                    color: f.color ?? hero?.text,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (f.onTap != null)
                  AppIcon(
                    AppIcons.chevronRight,
                    size: AppIconSize.sm,
                    color: muted,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

Widget _link(VoidCallback? onTap, Widget row) => onTap == null
    ? row
    : InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: row,
      );

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 3, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
