import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../chips/tone.dart';

/// Shows a floating snackbar, replacing any current one (so rapid actions
/// don't queue a backlog). [tone] adds a leading status icon.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Tone tone = Tone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final icon = switch (tone) {
    Tone.success => Icons.check_circle_outline,
    Tone.danger => Icons.error_outline,
    Tone.warning => Icons.warning_amber_outlined,
    Tone.info => Icons.info_outline,
    _ => null,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: tone.color(context)),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
}
