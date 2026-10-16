import 'package:flutter/material.dart';

/// THE count badge (owner 2026-10-12): a red pill with a page-colour ring,
/// "99+" past 99, nothing at 0. It floats off the top-right corner of what it
/// counts — an icon button's circle, a tab's label — about half of it outside
/// ([CountBadge.floating] places it); it never sits over the icon or text.
///
/// Used by [PpForgeIconButton] and [PpForgeTabBar]. Not [PpForgeBadge] (an inline label)
/// and not [CornerBadge] (the avatar's bottom-right mark).
class CountBadge extends StatelessWidget {
  const CountBadge({required this.count, super.key});

  /// The pill's height (it grows wider for 2–3 digits).
  static const double size = 18;

  final int count;

  /// [child] with the badge hanging off its top-right corner, anchored to the
  /// CHILD'S own bounds (never the parent's width). [count] 0 = just [child].
  /// [offset] is where the badge's top-right sits relative to the child's
  /// corner (a tab's label wants it a bit further out than a round button).
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
    return Semantics(
      label: '$count',
      child: Container(
        constraints: const BoxConstraints(minWidth: size, minHeight: size),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(size),
          // The page-colour ring: the badge reads on any background.
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 2,
          ),
        ),
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
    );
  }
}
