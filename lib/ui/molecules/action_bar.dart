import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../tokens/app_spacing.dart';

/// One action of an [ActionBar]: an icon and a short label.
class ActionBarItem {
  const ActionBarItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.submits = false,
  });

  final String label;
  final IconData? icon;

  /// null = disabled (dimmed).
  final VoidCallback? onPressed;

  /// The one emphasised action (filled); the rest are tonal.
  final bool primary;

  /// The action sends to the server (save, delete, create …): disabled while
  /// the app is offline ([PpForgeButton.submits]). Default false.
  final bool submits;
}

/// The actions under a hero (owner 2026-10-12): 2–4 EQUAL-width buttons in one
/// row, control height 40, icon + label — e.g. a wallet's
/// `[⟳ ปรับยอด] [+ รายการ] [⇄ โอน]`. Labels stay short; a longer one is
/// ellipsised, never wraps.
class ActionBar extends StatelessWidget {
  const ActionBar({
    required this.actions,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final List<ActionBarItem> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    assert(
      actions.length >= 2 && actions.length <= 4,
      'ActionBar holds 2–4 actions',
    );
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (final (i, a) in actions.indexed) ...[
            if (i > 0) const SizedBox(width: PpForgeSpacing.sm),
            Expanded(
              child: PpForgeButton(
                label: a.label,
                icon: a.icon,
                expand: true,
                variant: a.primary
                    ? PpForgeButtonVariant.primary
                    : PpForgeButtonVariant.tonal,
                submits: a.submits,
                onPressed: a.onPressed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
