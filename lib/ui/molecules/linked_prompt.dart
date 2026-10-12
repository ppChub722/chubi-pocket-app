import 'package:flutter/widgets.dart';

import '../atoms/app_button.dart';
import 'choice_dialog.dart';

/// What to do with the OTHER side of a linked record (owner 2026-10-13:
/// a tx and the event bill / recurring item it is linked to never sync by
/// themselves — the app asks at save / delete).
enum LinkedChoice {
  /// Save / delete only the record on this page; the link stays.
  thisSideOnly,

  /// Save / delete this one AND apply the same to the linked one.
  bothSides,
}

/// The one prompt for a linked record (owner 2026-10-13), events and
/// recurring alike:
///
///   [ยังก่อน]  [บันทึกเฉพาะฝั่งนี้]  [บันทึกและแก้อีกฝั่ง]
///
/// Every word comes in as a param (the app passes its l10n). Resolves the
/// [LinkedChoice], or null for [cancelLabel] / back / the barrier — nothing
/// is saved then and typed input stays. [destructive] (a delete): the
/// both-sides button is red.
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
