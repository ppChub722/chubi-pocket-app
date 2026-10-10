import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// A bar pinned under a page's or sheet's content — Save / Submit buttons:
/// surface fill, a hairline on top, side padding.
///
/// Its bottom clears the system gesture bar (`viewPadding`) — a sheet's
/// `useSafeArea` only covers the top, so buttons there sat ~8dp into it
/// (owner 2026-10-10). With the keyboard up it sits [keyboardGap] above
/// the keyboard instead (the keyboard already covers that inset).
class PinnedBar extends StatelessWidget {
  const PinnedBar({
    required this.child,
    this.bottomGap = AppSpacing.lg,
    this.keyboardGap = AppSpacing.sm,
    super.key,
  });

  final Widget child;

  /// Space under [child], above the gesture bar.
  final double bottomGap;

  /// Space under [child] while the keyboard is open.
  final double keyboardGap;

  /// The bottom padding [PinnedBar] uses — for a bar that can't be one.
  static double bottomPadding(
    BuildContext context, {
    double bottomGap = AppSpacing.lg,
    double keyboardGap = AppSpacing.sm,
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
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        bottomPadding(context, bottomGap: bottomGap, keyboardGap: keyboardGap),
      ),
      child: child,
    );
  }
}
