import 'package:flutter/material.dart';

import 'busy_scope.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/avatar_metrics.dart';
import 'corner_badge.dart';

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

  final double size;

  final Widget child;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  // Faded and inert under a locked [BusyScope] (a save runs elsewhere).
  @override
  Widget build(BuildContext context) => BusyLock(
    locked:
        (onTap != null || onLongPress != null) && BusyScope.isLocked(context),
    child: _build(context),
  );

  Widget _build(BuildContext context) {
    final stack = CornerBadge(
      size: size,
      icon: AppIcons.editBadge,
      show: onTap != null,
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
