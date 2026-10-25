import 'package:flutter/material.dart';

class CountBadge extends StatelessWidget {
  const CountBadge({required this.count, super.key});

  static const double size = 18;

  final int count;

  /// [child] with the badge hanging off its top-right corner, anchored to the
  /// CHILD'S own bounds (never the parent's width).
  static Widget floating({
    required Widget child,
    required int count,
    Offset offset = const Offset(-size / 3, -size / 3),
  }) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: offset.dy,
          right: offset.dx,
          child: IgnorePointer(child: CountBadge(count: count)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    // Always a true circle: one digit at [size], more digits a bit bigger
    // with the text scaled down to fit.
    final dimension = count < 10 ? size : size + 4;
    return Semantics(
      label: '$count',
      child: Container(
        width: dimension,
        height: dimension,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.error,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 2,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            count > 99 ? '99+' : '$count',
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onError,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
