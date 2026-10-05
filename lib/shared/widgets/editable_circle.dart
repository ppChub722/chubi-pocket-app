import 'package:flutter/material.dart';

/// Wraps any [child] in a tappable circle and overlays a pencil-edit badge
/// at the bottom-right when [onTap] is non-null.
///
/// Used wherever a circular avatar / icon is also a "tap to change" target
/// — currently the account form's `AccountCard` icon and the edit-profile
/// `UserAvatar`, with categories / tags / projects to follow when those
/// forms ship.
///
/// **No domain knowledge** — pass any widget as [child] and the widget
/// handles the tap behavior + pencil overlay identically. Pencil styling
/// (filled brand-primary background, white pencil, surface-color halo
/// border) is fixed across consumers so the affordance reads the same
/// everywhere.
class EditableCircle extends StatelessWidget {
  const EditableCircle({
    required this.size,
    required this.child,
    this.onTap,
    super.key,
  });

  /// Diameter of the underlying circle, in logical pixels. Used to size the
  /// pencil badge proportionally.
  final double size;

  /// The circle content — typically a `Container(shape: circle, color:
  /// ..., child: Icon(...))` or a `UserAvatar`.
  final Widget child;

  /// When non-null, the widget becomes tappable and the pencil badge
  /// appears. When null, [child] renders as-is with no overlay or
  /// interaction.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Badge scales with the circle but never drops below 18 dp — small
    // icons (44 dp account icons) would otherwise paint a pencil so tiny
    // it disappears.
    final badgeSize = (size * 0.3).clamp(18.0, 32.0);

    // The circle always occupies exactly [size] × [size]; the pencil badge
    // floats on top (absolute-positioned, pinned to the bottom-right
    // corner) so the footprint is identical whether or not [onTap] is set.
    // A consumer that toggles [onTap] (view ↔ edit) therefore never
    // reflows its layout.
    final stack = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          if (onTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.edit,
                  size: badgeSize * 0.55,
                  color: scheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return stack;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: stack,
      ),
    );
  }
}
