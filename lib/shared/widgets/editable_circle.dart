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
    if (onTap == null) return child;

    final scheme = Theme.of(context).colorScheme;
    // Badge scales with the circle but never drops below 18 dp — small
    // icons (44 dp account icons) would otherwise paint a pencil so tiny
    // it disappears.
    final badgeSize = (size * 0.3).clamp(18.0, 32.0);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size + badgeSize / 3,
          height: size + badgeSize / 3,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
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
        ),
      ),
    );
  }
}
