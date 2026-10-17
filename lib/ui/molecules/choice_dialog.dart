import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../atoms/app_button.dart';

class DialogChoice<T> {
  const DialogChoice({
    required this.value,
    required this.label,
    this.variant = AppButtonVariant.outlined,
  });

  final T value;
  final String label;

  final AppButtonVariant variant;
}

Future<T?> showChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required List<DialogChoice<T>> choices,
  String? message,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null) ...[
            Text(message),
            const SizedBox(height: AppSpacing.lg),
          ],
          for (var i = 0; i < choices.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: choices[i].label,
              variant: choices[i].variant,
              expand: true,
              onPressed: () => Navigator.pop(ctx, choices[i].value),
            ),
          ],
        ],
      ),
    ),
  );
}
