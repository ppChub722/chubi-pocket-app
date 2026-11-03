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
  final cancel = UiConfig.stringsOf(context).cancel;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        AppButton(
          label: cancelLabel ?? cancel,
          kind: ButtonIconKind.cancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppButton(
          label: confirmLabel,
          kind: destructive ? ButtonIconKind.delete : ButtonIconKind.confirm,
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
