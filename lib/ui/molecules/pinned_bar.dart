import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class PinnedBar extends StatelessWidget {
  const PinnedBar({
    required this.child,
    this.bottomGap = PpForgeSpacing.lg,
    this.keyboardGap = PpForgeSpacing.sm,
    super.key,
  });

  final Widget child;

  final double bottomGap;

  final double keyboardGap;

  /// The bottom padding [PinnedBar] uses — for a bar that can't be one.
  static double bottomPadding(
    BuildContext context, {
    double bottomGap = PpForgeSpacing.lg,
    double keyboardGap = PpForgeSpacing.sm,
  }) => MediaQuery.viewInsetsOf(context).bottom > 0
      ? keyboardGap
      : bottomGap + MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(
        PpForgeSpacing.lg,
        PpForgeSpacing.sm,
        PpForgeSpacing.lg,
        bottomPadding(context, bottomGap: bottomGap, keyboardGap: keyboardGap),
      ),
      child: child,
    );
  }
}
