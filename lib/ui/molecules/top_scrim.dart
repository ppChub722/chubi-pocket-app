import 'package:flutter/material.dart';

class TopScrim extends StatelessWidget {
  const TopScrim({
    required this.inset,
    this.barHeight = kToolbarHeight,
    this.color,
    super.key,
  });

  final double inset;

  final double barHeight;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).scaffoldBackgroundColor;
    final solid = inset <= 0 ? 0.0 : inset / (inset + barHeight);
    return IgnorePointer(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg, bg, bg.withValues(alpha: 0)],
              stops: [0, solid, 1],
            ),
          ),
        ),
      ),
    );
  }
}
