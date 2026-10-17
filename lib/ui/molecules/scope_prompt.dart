import 'package:flutter/widgets.dart';

import '../atoms/app_button.dart';
import '../organisms/edit_scope_choice.dart';
import 'choice_dialog.dart';

Future<EditScope?> showScopePrompt(
  BuildContext context, {
  required String title,
  required String cancelLabel,
  required String followingLabel,
  required String allLabel,
  String? message,
  bool destructive = false,
}) => showChoiceDialog<EditScope?>(
  context,
  title: title,
  message: message,
  choices: [
    DialogChoice(
      value: null,
      label: cancelLabel,
      variant: AppButtonVariant.text,
    ),
    DialogChoice(
      value: EditScope.following,
      label: followingLabel,
      variant: AppButtonVariant.outlined,
    ),
    DialogChoice(
      value: EditScope.all,
      label: allLabel,
      variant: destructive
          ? AppButtonVariant.destructive
          : AppButtonVariant.primary,
    ),
  ],
);
