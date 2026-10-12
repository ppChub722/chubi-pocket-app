import 'package:flutter/material.dart';

/// The profile chip: an avatar in the same frame as the [AppIconButton] chips
/// beside it — a neutral surface ring, or the bottom nav's active look
/// (primary container + primary ring) while [active] (the page it opens is on
/// screen). The ring, shadow and ripple follow the avatar's own shape
/// ([outline]: circle, squircle, leaf, …).
class AppAvatarButton extends StatelessWidget {
  const AppAvatarButton({
    required this.child,
    required this.onTap,
    this.outline,
    this.active = false,
    this.tooltip,
    this.size = 40,
    super.key,
  });

  /// The avatar (about 32 inside the 40 frame).
  final Widget child;
  final VoidCallback? onTap;

  /// The frame's corners; null = a circle.
  final BorderRadius? outline;
  final bool active;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = outline ?? BorderRadius.circular(size);
    final frame = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: radius,
        border: Border.all(
          color: active ? scheme.primary : scheme.outlineVariant,
          width: active ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
    final button = InkWell(
      customBorder: RoundedRectangleBorder(borderRadius: radius),
      onTap: onTap,
      child: frame,
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
