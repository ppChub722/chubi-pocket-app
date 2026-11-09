import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../tokens/button_icon_kind.dart';
import '../atoms/ui_config.dart';

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
          kind: ButtonIconKind.cancel,
          variant: PpForgeButtonVariant.text,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        PpForgeButton(
          label: confirmLabel,
          kind: destructive ? ButtonIconKind.delete : ButtonIconKind.confirm,
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
