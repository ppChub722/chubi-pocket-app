import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/avatar_metrics.dart';
import 'corner_badge.dart';

/// Wraps any [child] in a tappable circle and, when [onTap] is set, adds the
/// pencil-edit [CornerBadge] at the bottom-right.
///
/// Used wherever a circular avatar / icon is also a "tap to change" target
/// (account / category / contact / event / goal / tag icons, the profile
/// avatar).
///
/// **Never smaller than 40** ([AvatarMetrics.minEditableAvatar], owner
/// 2026-10-12): the pencil of a smaller circle would cover half of it. The
/// pencil scales with the circle ([AvatarMetrics.cornerBadge]).
///
/// **No domain knowledge** — pass any widget as [child] and the widget handles
/// the tap behaviour + pencil overlay identically.
class EditableCircle extends StatelessWidget {
  const EditableCircle({
    required this.size,
    required this.child,
    this.onTap,
    this.onLongPress,
    super.key,
  }) : assert(
         size >= AvatarMetrics.minEditableAvatar,
         'an editable circle is at least 40 — a smaller one cannot carry the '
         'pencil',
       );

  /// Diameter of the underlying circle, in logical pixels (≥ 40). Used to size
  /// the pencil badge proportionally.
  final double size;

  /// The circle content — typically an `IconDisplay`, an `PpForgeAvatar` or a
  /// `UserAvatar`.
  final Widget child;

  /// When non-null, the widget becomes tappable and the pencil badge
  /// appears. When null, [child] renders as-is with no overlay or
  /// interaction. The footprint is the same either way, so a consumer that
  /// toggles [onTap] (view ↔ edit) never reflows its layout.
  final VoidCallback? onTap;

  /// A long-press (view mode: enter edit). Works without [onTap]: the circle
  /// is then interactive but shows no pencil.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final stack = CornerBadge(
      size: size,
      icon: PpForgeIcons.editBadge,
      show: onTap != null,
      // The pencil is the whole point of an editable circle.
      essential: true,
      child: child,
    );
    if (onTap == null && onLongPress == null) return stack;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: const CircleBorder(),
        child: stack,
      ),
    );
  }
}
