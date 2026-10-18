import 'package:flutter/widgets.dart';

import '../atoms/app_button.dart';
import 'choice_dialog.dart';

enum LinkedChoice { thisSideOnly, bothSides }

Future<LinkedChoice?> showLinkedPrompt(
  BuildContext context, {
  required String title,
  required String cancelLabel,
  required String thisSideLabel,
  required String bothSidesLabel,
  String? message,
  bool destructive = false,
}) => showChoiceDialog<LinkedChoice?>(
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
      value: LinkedChoice.thisSideOnly,
      label: thisSideLabel,
      variant: AppButtonVariant.outlined,
    ),
    DialogChoice(
      value: LinkedChoice.bothSides,
      label: bothSidesLabel,
      variant: destructive
          ? AppButtonVariant.destructive
          : AppButtonVariant.primary,
    ),
  ],
);
