import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../buttons/app_button.dart';

/// One button of [showChoiceDialog].
class DialogChoice<T> {
  const DialogChoice({
    required this.value,
    required this.label,
    this.variant = AppButtonVariant.outlined,
  });

  final T value;
  final String label;

  /// primary = the suggested way out · destructive = loses something.
  final AppButtonVariant variant;
}

/// A dialog with more than two ways out ("keep as draft · keep editing ·
/// discard"). Buttons stack full-width in the given order. Resolves the
/// picked value, or null when dismissed (back / barrier).
///
/// Two ways out (confirm / cancel) → `showConfirmDialog`.
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
