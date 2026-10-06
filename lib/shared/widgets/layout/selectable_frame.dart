import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';

/// Selection ring around any card/tile: when [selected], draws a primary
/// outline (outside the child, so the child's own border stays) plus a
/// soft tint. The app's "this one is picked" look — card grids in pickers,
/// popover items, swatches.
class SelectableFrame extends StatelessWidget {
  const SelectableFrame({
    required this.selected,
    required this.child,
    this.radius = AppRadius.lg,
    this.color,
    this.gap = 3,
    super.key,
  });

  final bool selected;
  final Widget child;

  /// Corner radius of the child; the ring follows it at [gap] distance.
  final double radius;

  /// Ring colour; defaults to the primary colour.
  final Color? color;

  /// Space between the child and the ring.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final ring = color ?? Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: selected ? ring.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(radius + gap),
        border: Border.all(
          color: selected ? ring : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}
