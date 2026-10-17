import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../tokens/app_spacing.dart';

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

  final VoidCallback? onPressed;

  final bool primary;

  final bool submits;
}

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
      actions.isNotEmpty && actions.length <= 4,
      'ActionBar holds 1–4 actions',
    );
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (final (i, a) in actions.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: a.label,
                icon: a.icon,
                expand: true,
                variant: a.primary
                    ? AppButtonVariant.primary
                    : AppButtonVariant.tonal,
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
