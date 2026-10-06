import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../buttons/app_button.dart';

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
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        AppButton(
          label: cancelLabel ?? l.commonCancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppButton(
          label: confirmLabel,
          variant: destructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return ok ?? false;
}
