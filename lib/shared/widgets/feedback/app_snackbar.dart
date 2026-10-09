import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
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
}) => showAppSnackBarOn(
  ScaffoldMessenger.of(context),
  message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
);

/// [showAppSnackBar] on a messenger captured up front — for calls after an
/// `await` / pop, when the original context may already be gone.
void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  Tone tone = Tone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final icon = switch (tone) {
    Tone.success => AppIcons.success,
    Tone.danger => AppIcons.error,
    Tone.warning => AppIcons.warning,
    Tone.info => AppIcons.info,
    _ => null,
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              // Resolved inside the snackbar (under the app theme) so a
              // captured messenger works without a live caller context.
              Builder(
                builder: (ctx) => Icon(icon, size: 20, color: tone.color(ctx)),
              ),
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
