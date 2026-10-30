import 'package:flutter/material.dart';

import 'busy_scope.dart';

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

  final Widget child;
  final VoidCallback? onTap;

  final BorderRadius? outline;
  final bool active;
  final String? tooltip;
  final double size;

  // Faded and inert under a locked [BusyScope] (a save runs elsewhere).
  @override
  Widget build(BuildContext context) => BusyLock(
    locked: onTap != null && BusyScope.isLocked(context),
    child: _build(context),
  );

  Widget _build(BuildContext context) {
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
