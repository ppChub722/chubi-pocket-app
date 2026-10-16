import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// The body of a centred, narrow form page (the auth pages: sign in, register):
/// safe-area, vertically centred when short, scrolls when tall (keyboard), the
/// form capped at [maxWidth] and centred on wide screens.
class CenteredFormBody extends StatelessWidget {
  const CenteredFormBody({
    required this.child,
    this.maxWidth = 400,
    this.safeTop = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PpForgeSpacing.lg,
      vertical: PpForgeSpacing.xl,
    ),
    super.key,
  });

  final Widget child;
  final double maxWidth;

  /// false = no top safe-area inset (the page already has an app bar / its own
  /// top spacing, e.g. register).
  final bool safeTop;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: safeTop,
    child: Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    ),
  );
}
