import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';

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

  final double radius;

  final Color? color;

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
