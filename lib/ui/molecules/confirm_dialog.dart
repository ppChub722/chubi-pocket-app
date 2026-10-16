import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';

/// The app's one confirmation dialog. Resolves `true` only when the user
/// taps the confirm button (dismiss / cancel / back → `false`).
///
/// [destructive] paints the confirm button red — use for delete, leave,
/// discard, reject.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final cancel = PpForgeConfig.stringsOf(context).cancel;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        PpForgeButton(
          label: cancelLabel ?? cancel,
          variant: PpForgeButtonVariant.text,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        PpForgeButton(
          label: confirmLabel,
          variant: destructive
              ? PpForgeButtonVariant.destructive
              : PpForgeButtonVariant.primary,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return ok ?? false;
}
